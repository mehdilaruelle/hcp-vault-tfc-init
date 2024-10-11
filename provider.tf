provider "vault" {
  address = local.vault_addr
  token   = hcp_vault_cluster_admin_token.this.token
}

provider "gitlab" {
  base_url = "${var.gitlab_domain}/api/v4"
}

provider "tfe" {
  organization = var.tfc_org_name
}

provider "hcp" {}

provider "aws" {
  region = var.region
}
