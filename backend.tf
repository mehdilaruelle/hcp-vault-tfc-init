terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~>4.4.0"
    }
    gitlab = {
      source  = "gitlabhq/gitlab"
      version = "~>17.4.0"
    }
    hcp = {
      source  = "hashicorp/hcp"
      version = "~>0.96.0"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "~>0.59.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.70.0"
    }
  }

  backend "remote" {
    organization = "mlaruelle"

    workspaces {
      name = "vault-prod-eu"
    }
  }
}
