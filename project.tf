data "tfe_organization" "current" {}

resource "vault_auth_backend" "aws" {
  description = "Auth backend to auth project in AWS env"
  type        = "aws"
  path        = "${var.project_name}-project-aws"
}

# HCP Vault do NOT have the permission to assume role so
# we use IAM user credential instead of a direct assume
# role from instance profile
resource "vault_aws_auth_backend_client" "user_iam" {
  backend    = vault_auth_backend.aws.path
  access_key = aws_iam_access_key.aws_engine.id
  secret_key = aws_iam_access_key.aws_engine.secret
}

resource "vault_aws_auth_backend_sts_role" "role" {
  backend    = vault_auth_backend.aws.path
  account_id = data.aws_caller_identity.current.account_id
  sts_role   = aws_iam_role.auth_engine.arn
}

resource "vault_mount" "db" {
  description = "Secret engine for project to create DB secrets"
  type        = "database"
  path        = "${var.project_name}-project-db"
}

// Give to project the right to authentificate and use read_secrets
data "vault_policy_document" "project" {
  rule {
    path         = "${vault_mount.db.path}/creds/${var.project_name}"
    capabilities = ["read"]
    description  = "Allow to read db secrets"
  }
}

resource "vault_policy" "project" {
  name   = var.project_name
  policy = data.vault_policy_document.project.hcl
}

resource "gitlab_project" "project" {
  name        = "${var.project_name}-project"
  description = "${var.project_name} project to deploy an app in AWS with Terraform and Vault"

  initialize_with_readme = true
  shared_runners_enabled = true
  default_branch         = var.gitlab_project_branch

  visibility_level = "private"
}

resource "gitlab_project_variable" "vault_secret_aws_role" {
  project = gitlab_project.project.id
  key     = "TF_VAR_vault_secret_aws_role"
  value   = vault_jwt_auth_backend_role.pipeline.role_name
}

resource "gitlab_project_variable" "vault_pipeline_path" {
  project = gitlab_project.project.id
  key     = "TF_VAR_vault_pipeline_auth_path"
  value   = vault_jwt_auth_backend.gitlab.path
}

resource "gitlab_project_variable" "vault_secret_aws_path" {
  project = gitlab_project.project.id
  key     = "TF_VAR_vault_secret_aws_backend"
  value   = vault_aws_secret_backend.aws.path
}

resource "gitlab_project_variable" "project_name" {
  project = gitlab_project.project.id
  key     = "TF_VAR_project_name"
  value   = var.project_name
}

resource "gitlab_project_variable" "vault_addr" {
  project = gitlab_project.project.id
  key     = "TF_VAR_vault_addr"
  value   = local.vault_addr
}

resource "gitlab_project_variable" "vault_addr_env" {
  project = gitlab_project.project.id
  key     = "VAULT_ADDR"
  value   = local.vault_addr
}

resource "gitlab_project_variable" "gitlab_token_aud" {
  project = gitlab_project.project.id
  key     = "TOKEN_AUD"
  value   = local.vault_domain_name
}

resource "gitlab_project_variable" "vault_secret_terraform_path" {
  project = gitlab_project.project.id
  key     = "VAULT_SECRET_TERRAFORM_PATH"
  value   = "${vault_terraform_cloud_secret_role.pipeline.backend}/creds/${vault_terraform_cloud_secret_role.pipeline.name}"
}

resource "gitlab_project_variable" "vault_secret_db_path" {
  project = gitlab_project.project.id
  key     = "TF_VAR_vault_db_backend"
  value   = vault_mount.db.path
}

resource "gitlab_project_variable" "terraform_vault_namespace" {
  project = gitlab_project.project.id
  key     = "TF_VAR_vault_agent_parameters"
  value   = "VAULT_NAMESPACE=${hcp_vault_cluster.main.namespace}"
}

resource "gitlab_project_variable" "vault_namespace" {
  project = gitlab_project.project.id
  key     = "VAULT_NAMESPACE"
  value   = hcp_vault_cluster.main.namespace
}

resource "gitlab_project_variable" "vault_app_secret_db_path" {
  project = gitlab_project.project.id
  key     = "TF_VAR_vault_app_secret_db_path"
  value   = vault_mount.db.path
}

resource "gitlab_project_variable" "vault_app_auth_aws_path" {
  project = gitlab_project.project.id
  key     = "TF_VAR_vault_app_auth_aws_path"
  value   = vault_auth_backend.aws.path
}

resource "gitlab_project_variable" "tfc_org_name" {
  project = gitlab_project.project.id
  key     = "TFC_ORG_NAME"
  value   = data.tfe_organization.current.name
}

resource "tfe_workspace" "project" {
  name         = "${var.project_name}-project"
  organization = data.tfe_organization.current.name

  vcs_repo {
    identifier     = gitlab_project.project.path_with_namespace
    branch         = var.gitlab_project_branch
    oauth_token_id = var.vcs_id
  }
}

resource "tfe_workspace_settings" "project" {
  workspace_id   = tfe_workspace.project.id
  execution_mode = "local"
}
