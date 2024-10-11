variable "region" {
  description = "AWS regions"
  default     = "eu-west-1"
}

variable "tfc_org_name" {
  description = "The name of the Terraform Cloud Organization where workspace are"
}

variable "vcs_id" {
  description = "value"
}

##### OPTIONS #####
variable "hcp_vault_cidr" {
  description = "The CIDR used in the HCP for the HashiCorp Virtual Network (HVN)"
  default     = "192.168.0.0/16"
}

variable "hcp_vault_tier_level" {
  description = "The HCP Vault tier level to use"
  default     = "dev"
}

variable "is_hcp_vault_public" {
  description = "If this value is true, Vault endpoint will be public."
  type        = bool
  default     = true
}

variable "gitlab_domain" {
  description = "The domain name of your gitlab (e.g: gitlab.com)"
  default     = "https://gitlab.com"
}

variable "project_name" {
  description = "Project name (ex: web)"
  default     = "web"
}

variable "gitlab_project_branch" {
  description = "The pipeline project branch to authorize to auth with Vault"
  default     = "main"
}

variable "aws_secret_default_ttl" {
  description = "The default lease ttl for AWS secret engine (default: 10min)"
  default     = 600
}

variable "aws_secret_max_ttl" {
  description = "The max lease ttl for AWS secret engine (default: 15min)"
  default     = 900
}

variable "jwt_token_max_ttl" {
  description = "The token max ttl for JWT auth backend (default: 15min)"
  default     = 900
}

variable "jwt_auth_tune_default_ttl" {
  description = "The tune default lease ttl for JWT auth backend (default: 10min)"
  default     = "10m"
}
variable "jwt_auth_tune_max_ttl" {
  description = "The tune max lease ttl for JWT auth backend (default: 15min)"
  default     = "15m"
}
