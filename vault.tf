resource "hcp_hvn" "vault" {
  hvn_id         = var.project_name
  cloud_provider = "aws"
  region         = var.region
  cidr_block     = var.hcp_vault_cidr
}

resource "hcp_vault_cluster" "main" {
  cluster_id      = var.project_name
  hvn_id          = hcp_hvn.vault.hvn_id
  tier            = var.hcp_vault_tier_level
  public_endpoint = var.is_hcp_vault_public
}

resource "hcp_vault_cluster_admin_token" "this" {
  cluster_id = hcp_vault_cluster.main.cluster_id
}
