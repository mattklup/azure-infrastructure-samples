data "azurerm_client_config" "current" {}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.91.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "resource_group" {
  name     = "${var.resource_group_name}-${var.resource_group_location}"
  location = var.resource_group_location
}

resource "azurerm_virtual_network" "virtual_network" {
    name                = "${var.resource_group_name.name}"
    address_space       = ["10.0.0.0/24"]
    location            = "westus"
    resource_group_name = azurerm_resource_group.resource_group.name
}
