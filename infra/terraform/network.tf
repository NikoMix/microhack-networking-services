module "workload_nsg" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.1"

  name                = local.names.workload_nsg
  location            = azurerm_resource_group.this["spoke"].location
  resource_group_name = azurerm_resource_group.this["spoke"].name
  enable_telemetry    = var.enable_telemetry
  tags                = local.tags

  security_rules = {
    allow_virtual_network_inbound = {
      name                       = "Allow-VNet-Inbound"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    }
    deny_internet_inbound = {
      name                       = "Deny-Internet-Inbound"
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    }
  }
}

module "firewall_public_ip" {
  source  = "Azure/avm-res-network-publicipaddress/azurerm"
  version = "0.2.1"

  name                = local.names.firewall_pip
  location            = azurerm_resource_group.this["hub"].location
  resource_group_name = azurerm_resource_group.this["hub"].name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  enable_telemetry    = var.enable_telemetry
  tags                = local.tags
}

module "firewall_policy" {
  source  = "Azure/avm-res-network-firewallpolicy/azurerm"
  version = "0.3.4"

  name                = local.names.firewall_policy
  location            = azurerm_resource_group.this["hub"].location
  resource_group_name = azurerm_resource_group.this["hub"].name
  firewall_policy_sku = "Premium"

  # Premium-only IDPS in Deny mode: blocks traffic matching known attack signatures
  # (PSD2 Art. 95 network anomaly detection). Benign lab HTTP/HTTPS is unaffected.
  # TLS inspection is design-only: it requires a customer intermediate CA certificate
  # provisioned to Key Vault.
  firewall_policy_intrusion_detection = {
    mode = "Deny"
  }

  enable_telemetry = var.enable_telemetry
  tags             = local.tags
}

module "hub_vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.19.0"

  name             = local.names.hub_vnet
  location         = azurerm_resource_group.this["hub"].location
  parent_id        = azurerm_resource_group.this["hub"].id
  address_space    = var.hub_address_space
  enable_telemetry = var.enable_telemetry
  tags             = local.tags

  subnets = {
    AzureFirewallSubnet = {
      name             = "AzureFirewallSubnet"
      address_prefixes = ["10.0.0.0/26"]
    }
    AzureBastionSubnet = {
      name             = "AzureBastionSubnet"
      address_prefixes = ["10.0.1.0/26"]
    }
    GatewaySubnet = {
      name             = "GatewaySubnet"
      address_prefixes = ["10.0.2.0/27"]
    }
  }
}

module "azure_firewall" {
  source  = "Azure/avm-res-network-azurefirewall/azurerm"
  version = "0.4.0"

  name                = local.names.firewall
  location            = azurerm_resource_group.this["hub"].location
  resource_group_name = azurerm_resource_group.this["hub"].name
  firewall_sku_name   = "AZFW_VNet"
  firewall_sku_tier   = "Premium"
  firewall_policy_id  = module.firewall_policy.resource_id
  firewall_zones      = ["1", "2", "3"]
  enable_telemetry    = var.enable_telemetry
  tags                = local.tags

  ip_configurations = {
    default = {
      name                 = "ipconfig1"
      subnet_id            = module.hub_vnet.subnets["AzureFirewallSubnet"].resource_id
      public_ip_address_id = module.firewall_public_ip.public_ip_id
    }
  }
}

resource "azurerm_route_table" "workload" {
  name                = local.names.workload_rt
  location            = azurerm_resource_group.this["spoke"].location
  resource_group_name = azurerm_resource_group.this["spoke"].name
  tags                = local.tags

  route {
    name                   = "DefaultToAzureFirewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = module.azure_firewall.resource.ip_configuration[0].private_ip_address
  }
}

module "spoke_vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.19.0"

  name             = local.names.spoke_vnet
  location         = azurerm_resource_group.this["spoke"].location
  parent_id        = azurerm_resource_group.this["spoke"].id
  address_space    = var.spoke_address_space
  enable_telemetry = var.enable_telemetry
  tags             = local.tags

  subnets = {
    workload = {
      name             = "snet-workload"
      address_prefixes = ["10.1.0.0/24"]
      network_security_group = {
        id = module.workload_nsg.resource_id
      }
      route_table = {
        id = azurerm_route_table.workload.id
      }
    }
    private_endpoints = {
      name                              = "snet-pe"
      address_prefixes                  = ["10.1.1.0/24"]
      private_endpoint_network_policies = "Disabled"
    }
    app_gateway = {
      name             = "snet-appgw"
      address_prefixes = ["10.1.2.0/24"]
    }
    # Dedicated subnet hosting the Application Gateway Private Link service NICs.
    # Front Door Premium connects to the App Gateway frontend through this subnet,
    # which therefore must disable private-link-service network policies.
    app_gateway_private_link = {
      name                                          = "snet-agw-pl"
      address_prefixes                              = ["10.1.4.0/24"]
      private_link_service_network_policies_enabled = false
    }
    load_balancer = {
      name             = "snet-lb"
      address_prefixes = ["10.1.3.0/24"]
    }
  }
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                         = "cfs-hub-to-spoke-${local.region_code}"
  resource_group_name          = azurerm_resource_group.this["hub"].name
  virtual_network_name         = module.hub_vnet.name
  remote_virtual_network_id    = module.spoke_vnet.resource_id
  allow_forwarded_traffic      = true
  allow_gateway_transit        = var.deploy_vpn_gateway
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                         = "cfs-spoke-to-hub-${local.region_code}"
  resource_group_name          = azurerm_resource_group.this["spoke"].name
  virtual_network_name         = module.spoke_vnet.name
  remote_virtual_network_id    = module.hub_vnet.resource_id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  use_remote_gateways          = var.deploy_vpn_gateway

  depends_on = [azurerm_virtual_network_peering.hub_to_spoke]
}

