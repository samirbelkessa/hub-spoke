terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
  }
}
provider "azurerm" {
  alias = "spoke"
  features {}
  subscription_id = var.spoke_subscription_id
}
provider "azurerm" {
  alias = "hub"
  features {}
  subscription_id = var.hub_subscription_id
}
