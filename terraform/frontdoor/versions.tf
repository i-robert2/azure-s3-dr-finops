terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.6"
    }
  }
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

data "terraform_remote_state" "shared" {
  backend = "azurerm"
  config = {
    resource_group_name  = var.tfstate_rg
    storage_account_name = var.tfstate_sa
    container_name       = var.tfstate_container
    key                  = "s3-shared.tfstate"
  }
}
