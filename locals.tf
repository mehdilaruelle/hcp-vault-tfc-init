locals {
  vault_addr        = hcp_vault_cluster.main.vault_public_endpoint_url
  vault_domain_name = join("", slice(split(":", local.vault_addr), 0, 2))
}
