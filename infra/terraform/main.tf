data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "this" {
  for_each = local.resource_groups

  name     = each.value
  location = var.location
  tags     = local.tags
}

resource "tls_private_key" "lab_admin" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

module "log_analytics" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.5.1"

  name                = local.names.law
  location            = azurerm_resource_group.this["mgmt"].location
  resource_group_name = azurerm_resource_group.this["mgmt"].name
  enable_telemetry    = var.enable_telemetry
  tags                = local.tags
}

