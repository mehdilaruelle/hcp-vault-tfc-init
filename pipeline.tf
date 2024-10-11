resource "vault_jwt_auth_backend" "gitlab" {
  description        = "JWT auth backend for Gitlab-CI pipeline"
  path               = "${var.project_name}-pipeline"
  oidc_discovery_url = var.gitlab_domain
  bound_issuer       = var.gitlab_domain
  default_role       = "default"

  tune {
    default_lease_ttl = var.jwt_auth_tune_default_ttl
    max_lease_ttl     = var.jwt_auth_tune_max_ttl
    token_type        = "default-service"
  }
}

# HCP Vault do NOT have the permission to assume role so
# we use IAM user credential instead of a direct assume
# role from instance profile
resource "vault_aws_secret_backend" "aws" {
  description = "AWS secret engine for Gitlab-CI pipeline"
  path        = "${var.project_name}-pipeline-aws"
  region      = var.region

  access_key = aws_iam_access_key.aws_engine.id
  secret_key = aws_iam_access_key.aws_engine.secret

  default_lease_ttl_seconds = var.aws_secret_default_ttl
  max_lease_ttl_seconds     = var.aws_secret_max_ttl
}

resource "tfe_team" "pipeline" {
  name         = var.project_name
  organization = data.tfe_organization.current.name
}

resource "tfe_team_token" "pipeline" {
  team_id = tfe_team.pipeline.id
}

resource "tfe_team_access" "pipeline" {
  access       = "write"
  team_id      = tfe_team.pipeline.id
  workspace_id = tfe_workspace.project.id
}

resource "vault_terraform_cloud_secret_backend" "pipeline" {
  description = "Manages the Terraform Cloud backend for Gitlab-CI pipeline"

  backend = "${var.project_name}-pipeline-tfc"
  token   = tfe_team_token.pipeline.token
}

resource "vault_terraform_cloud_secret_role" "pipeline" {
  backend = vault_terraform_cloud_secret_backend.pipeline.backend
  name    = "${var.project_name}-pipeline"
  team_id = tfe_team_token.pipeline.team_id
  ttl     = 600
}

data "vault_policy_document" "pipeline_aws_read" {
  rule {
    required_parameters = []
    path                = "${vault_aws_secret_backend.aws.path}/sts/${vault_aws_secret_backend_role.pipeline.name}"
    capabilities        = ["read"]
    description         = "Allow to read AWS secrets"
  }
  rule {
    required_parameters = []
    path                = "${vault_mount.db.path}/*"
    capabilities        = ["read", "update", "create", "delete", "list"]
    description         = "Allow to manage db secrets"
  }
  rule {
    required_parameters = []
    path                = "auth/${vault_auth_backend.aws.path}/*"
    capabilities        = ["read", "update", "create", "delete", "list"]
    description         = "Allow to manage authentification into the Vault with AWS auth method"
  }
  rule {
    required_parameters = []
    path                = "auth/token/create"
    capabilities        = ["update"]
    description         = "Allow pipeline to create a Vault child token when using Terraform"
  }
  rule {
    required_parameters = []
    path                = "${vault_terraform_cloud_secret_role.pipeline.backend}/creds/${vault_terraform_cloud_secret_role.pipeline.name}"
    capabilities        = ["read"]
    description         = "Allow to read Terraform Cloud secrets"
  }
}

resource "vault_policy" "pipeline" {
  name   = "${var.project_name}-pipeline"
  policy = data.vault_policy_document.pipeline_aws_read.hcl
}

resource "vault_jwt_auth_backend_role" "pipeline" {
  backend   = vault_jwt_auth_backend.gitlab.path
  role_type = "jwt"

  role_name      = "${var.project_name}-pipeline"
  token_policies = ["default", vault_policy.pipeline.name]

  bound_audiences = [local.vault_domain_name]
  bound_claims = {
    project_id = gitlab_project.project.id
    ref        = var.gitlab_project_branch
    ref_type   = "branch"
  }
  user_claim             = "user_email"
  token_explicit_max_ttl = var.jwt_token_max_ttl
}

resource "vault_aws_secret_backend_role" "pipeline" {
  backend         = vault_aws_secret_backend.aws.path
  name            = "${var.project_name}-pipeline"
  credential_type = "assumed_role"

  role_arns = [aws_iam_role.application.arn]

  policy_document = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "rds:*",
        "iam:CreateServiceLinkedRole"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:GetUser"
      ],
      "Resource": "arn:aws:iam::*:user/$${aws:username}"
    }
  ]
}
EOF
}
