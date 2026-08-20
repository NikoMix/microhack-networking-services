module "internal_load_balancer" {
  source  = "Azure/avm-res-network-loadbalancer/azurerm"
  version = "0.5.0"

  name                = local.names.load_balancer
  location            = azurerm_resource_group.this["spoke"].location
  resource_group_name = azurerm_resource_group.this["spoke"].name
  sku                 = "Standard"
  enable_telemetry    = var.enable_telemetry
  tags                = local.tags

  frontend_ip_configurations = {
    private = {
      name                                   = "cfsPrivateFrontend"
      frontend_private_ip_subnet_resource_id = module.spoke_vnet.subnets["load_balancer"].resource_id
      frontend_private_ip_address_allocation = "Dynamic"
    }
  }

  backend_address_pools = {
    workload = {
      name                        = "cfs-workload-pool"
      virtual_network_resource_id = module.spoke_vnet.resource_id
    }
  }

  frontend_subnet_resource_id = module.spoke_vnet.subnets["load_balancer"].resource_id
}

resource "azurerm_web_application_firewall_policy" "app_gateway" {
  name                = local.names.app_gateway_waf
  resource_group_name = azurerm_resource_group.this["spoke"].name
  location            = azurerm_resource_group.this["spoke"].location
  tags                = local.tags

  policy_settings {
    enabled                     = true
    mode                        = "Prevention"
    request_body_check          = true
    file_upload_limit_in_mb     = 100
    max_request_body_size_in_kb = 128
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
}

module "application_gateway" {
  source  = "Azure/avm-res-network-applicationgateway/azurerm"
  version = "0.5.3"

  name                = local.names.app_gateway
  location            = azurerm_resource_group.this["spoke"].location
  resource_group_name = azurerm_resource_group.this["spoke"].name
  enable_telemetry    = var.enable_telemetry
  tags                = local.tags

  sku = {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  autoscale_configuration = {
    min_capacity = 2
    max_capacity = 3
  }

  gateway_ip_configuration = {
    name      = "appGatewayIpConfig"
    subnet_id = module.spoke_vnet.subnets["app_gateway"].resource_id
  }

  public_ip_address_configuration = {
    create_public_ip_enabled = true
    public_ip_name           = local.names.app_gateway_pip
    allocation_method        = "Static"
    sku                      = "Standard"
    zones                    = ["1", "2", "3"]
  }

  # Name of the frontend IP configuration that exposes the Private Link service.
  # Front Door Premium references this name as the shared-private-link "group id".
  frontend_ip_configuration_public_name = "public"

  # Private Link configuration so Front Door Premium can reach the App Gateway
  # frontend privately. The NICs land in the dedicated snet-agw-pl subnet (network
  # policies disabled). The connection is approved on the App Gateway side post-deploy.
  #
  # KNOWN LIMITATION (Terraform mirror only): the AVM
  # Azure/avm-res-network-applicationgateway module (<=0.5.2) creates this Private Link
  # configuration and names the public frontend "public", but its public-frontend block
  # exposes no field to bind the PL config onto that frontend (only the *private*
  # frontend block accepts private_link_configuration_name). The Bicep path
  # (infra/bicep/modules/app-gateway.bicep) IS the authoritative implementation for the
  # public-frontend Private Link wiring; on Terraform, approve/verify the connection
  # manually or use Bicep for this feature. Tracked upstream.
  private_link_configuration = [
    {
      name = "agw-pl"
      ip_configuration = [
        {
          name                          = "agw-pl-ipconfig"
          primary                       = true
          private_ip_address_allocation = "Dynamic"
          subnet_id                     = module.spoke_vnet.subnets["app_gateway_private_link"].resource_id
        }
      ]
    }
  ]

  frontend_ports = {
    http = {
      name = "frontend-port-80"
      port = 80
    }
  }

  http_listeners = {
    http = {
      name               = "http-listener"
      frontend_port_name = "frontend-port-80"
      firewall_policy_id = azurerm_web_application_firewall_policy.app_gateway.id
    }
  }

  backend_address_pools = {
    workload = {
      name         = "workload-backend-pool"
      ip_addresses = ["10.1.0.4"]
    }
  }

  backend_http_settings = {
    http = {
      name            = "http-settings"
      port            = 80
      protocol        = "Http"
      request_timeout = 30
    }
  }

  request_routing_rules = {
    http = {
      name                       = "http-basic-rule"
      rule_type                  = "Basic"
      http_listener_name         = "http-listener"
      backend_address_pool_name  = "workload-backend-pool"
      backend_http_settings_name = "http-settings"
      priority                   = 100
    }
  }

  app_gateway_waf_policy_resource_id = azurerm_web_application_firewall_policy.app_gateway.id
}

module "front_door" {
  count = var.deploy_front_door ? 1 : 0

  source  = "Azure/avm-res-cdn-profile/azurerm"
  version = "0.1.9"

  name                = local.names.front_door
  location            = "global"
  resource_group_name = azurerm_resource_group.this["spoke"].name
  sku                 = "Premium_AzureFrontDoor"
  enable_telemetry    = var.enable_telemetry
  tags                = local.tags

  front_door_endpoints = {
    default = {
      name    = local.names.front_door_endpoint
      enabled = true
      tags    = local.tags
    }
  }

  front_door_origin_groups = {
    app_gateway = {
      name = "cfs-appgw-origin-group"
      health_probe = {
        default = {
          interval_in_seconds = 240
          path                = "/"
          protocol            = "Http"
          request_type        = "HEAD"
        }
      }
      load_balancing = {
        default = {
          additional_latency_in_milliseconds = 0
          sample_size                        = 4
          successful_samples_required        = 3
        }
      }
    }
  }

  front_door_origins = {
    app_gateway = {
      name                           = "cfs-appgw-origin"
      origin_group_key               = "app_gateway"
      host_name                      = module.application_gateway.new_public_ip_address
      host_header                    = module.application_gateway.new_public_ip_address
      certificate_name_check_enabled = false
      http_port                      = 80
      https_port                     = 443
      priority                       = 1
      weight                         = 1000

      # Premium-only: reach the Application Gateway over Private Link. The connection
      # lands as "Pending" and is approved on the App Gateway side post-deploy. The
      # frontend IP config name ("public") is the Private Link group id (derived by
      # Azure from the App Gateway's private link configuration; target_type must be
      # null for an Application Gateway target).
      private_link = {
        agw = {
          request_message        = "Front Door Premium private link to the CFS Application Gateway"
          location               = azurerm_resource_group.this["spoke"].location
          private_link_target_id = module.application_gateway.resource_id
        }
      }
    }
  }

  front_door_routes = {
    default = {
      name                   = "default-route"
      endpoint_key           = "default"
      origin_group_key       = "app_gateway"
      origin_keys            = ["app_gateway"]
      forwarding_protocol    = "HttpOnly"
      https_redirect_enabled = true
      patterns_to_match      = ["/*"]
      supported_protocols    = ["Http", "Https"]
    }
  }

  front_door_firewall_policies = {
    default = {
      name                = local.names.front_door_waf
      resource_group_name = azurerm_resource_group.this["spoke"].name
      sku_name            = "Premium_AzureFrontDoor"
      enabled             = true
      mode                = "Prevention"

      managed_rules = {
        microsoft_default = {
          type    = "Microsoft_DefaultRuleSet"
          version = "2.1"
          action  = "Block"
        }
        microsoft_bot = {
          type    = "Microsoft_BotManagerRuleSet"
          version = "1.0"
          action  = "Block"
        }
      }
    }
  }

  front_door_security_policies = {
    default = {
      name = "cfs-afd-security-policy-${local.region_code}"
      firewall = {
        front_door_firewall_policy_key = "default"
        association = {
          endpoint_keys     = ["default"]
          patterns_to_match = ["/*"]
        }
      }
    }
  }
}
