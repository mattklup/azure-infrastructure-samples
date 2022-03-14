data "azurerm_client_config" "current" {}

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=>2.91.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group_name}-${var.resource_group_location}"
  location = var.resource_group_location
}
