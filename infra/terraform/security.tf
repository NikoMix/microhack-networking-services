module "bastion_public_ip" {
  source  = "Azure/avm-res-network-publicipaddress/azurerm"
  version = "0.2.1"

  name                = local.names.bastion_pip
  location            = azurerm_resource_group.this["hub"].location
  resource_group_name = azurerm_resource_group.this["hub"].name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  enable_telemetry    = var.enable_telemetry
  tags                = local.tags
}

module "bastion" {
  source  = "Azure/avm-res-network-bastionhost/azurerm"
  version = "0.9.0"

  name             = local.names.bastion
  location         = azurerm_resource_group.this["hub"].location
  parent_id        = azurerm_resource_group.this["hub"].id
  sku              = "Standard"
  scale_units      = 2
  enable_telemetry = var.enable_telemetry
  tags             = local.tags

  ip_configuration = {
    name                 = "bastion-ipconfig"
    subnet_id            = module.hub_vnet.subnets["AzureBastionSubnet"].resource_id
    create_public_ip     = false
    public_ip_address_id = module.bastion_public_ip.public_ip_id
  }
}

module "vpn_gateway_public_ip" {
  count = var.deploy_vpn_gateway ? 1 : 0

  source  = "Azure/avm-res-network-publicipaddress/azurerm"
  version = "0.2.1"

  name                = local.names.vpn_gateway_pip
  location            = azurerm_resource_group.this["hub"].location
  resource_group_name = azurerm_resource_group.this["hub"].name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  enable_telemetry    = var.enable_telemetry
  tags                = local.tags
}

module "vpn_gateway" {
  count = var.deploy_vpn_gateway ? 1 : 0

  source  = "Azure/avm-ptn-vnetgateway/azurerm"
  version = "0.10.3"

  name                              = local.names.vpn_gateway
  location                          = azurerm_resource_group.this["hub"].location
  parent_id                         = azurerm_resource_group.this["hub"].id
  type                              = "Vpn"
  vpn_type                          = "RouteBased"
  sku                               = "VpnGw1"
  subnet_creation_enabled           = false
  virtual_network_gateway_subnet_id = module.hub_vnet.subnets["GatewaySubnet"].resource_id
  enable_telemetry                  = var.enable_telemetry
  tags                              = local.tags

  ip_configurations = {
    default = {
      name = "vnetGatewayConfig"
      public_ip = {
        creation_enabled = false
        id               = module.vpn_gateway_public_ip[0].public_ip_id
      }
    }
  }
}

# ExpressRoute design note:
# This microhack mirror documents ExpressRoute as a design-only extension point. No circuit,
# authorization, peering, or ExpressRoute gateway is provisioned; the deployed gateway above is
# a real route-based VPN gateway (VpnGw1) for validation-only topology parity.

module "private_dns_key_vault" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "0.5.0"

  domain_name      = local.private_dns_zones.key_vault
  parent_id        = azurerm_resource_group.this["spoke"].id
  enable_telemetry = var.enable_telemetry
  tags             = local.tags

  virtual_network_links = {
    hub = {
      name               = "cfs-hub-kv-dnslink-${local.region_code}"
      virtual_network_id = module.hub_vnet.resource_id
    }
    spoke = {
      name               = "cfs-spoke-kv-dnslink-${local.region_code}"
      virtual_network_id = module.spoke_vnet.resource_id
    }
  }
}

module "private_dns_blob" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "0.5.0"

  domain_name      = local.private_dns_zones.blob
  parent_id        = azurerm_resource_group.this["spoke"].id
  enable_telemetry = var.enable_telemetry
  tags             = local.tags

  virtual_network_links = {
    hub = {
      name               = "cfs-hub-blob-dnslink-${local.region_code}"
      virtual_network_id = module.hub_vnet.resource_id
    }
    spoke = {
      name               = "cfs-spoke-blob-dnslink-${local.region_code}"
      virtual_network_id = module.spoke_vnet.resource_id
    }
  }
}

module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.2"

  name                          = local.names.key_vault
  location                      = azurerm_resource_group.this["spoke"].location
  resource_group_name           = azurerm_resource_group.this["spoke"].name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  purge_protection_enabled      = true
  public_network_access_enabled = false
  enable_telemetry              = var.enable_telemetry
  tags                          = local.tags

  network_acls = {
    bypass         = "AzureServices"
    default_action = "Deny"
  }

  private_endpoints = {
    vault = {
      name                          = "cfs-kv-pe-${local.region_code}"
      subnet_resource_id            = module.spoke_vnet.subnets["private_endpoints"].resource_id
      private_dns_zone_resource_ids = [module.private_dns_key_vault.resource_id]
      tags                          = local.tags
    }
  }
}

module "storage_account" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.7.3"

  name                          = local.names.storage_account
  location                      = azurerm_resource_group.this["spoke"].location
  parent_id                     = azurerm_resource_group.this["spoke"].id
  account_tier                  = "Standard"
  account_replication_type      = "ZRS"
  shared_access_key_enabled     = false
  public_network_access_enabled = false
  enable_telemetry              = var.enable_telemetry
  tags                          = local.tags

  network_rules = {
    bypass         = ["AzureServices"]
    default_action = "Deny"
  }

  private_endpoints = {
    blob = {
      name                          = "cfs-blob-pe-${local.region_code}"
      subnet_resource_id            = module.spoke_vnet.subnets["private_endpoints"].resource_id
      subresource_name              = "blob"
      private_dns_zone_resource_ids = [module.private_dns_blob.resource_id]
      tags                          = local.tags
    }
  }
}
