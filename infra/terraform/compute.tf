module "linux_vm" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.21.0"

  name                            = local.names.vm
  location                        = azurerm_resource_group.this["spoke"].location
  resource_group_name             = azurerm_resource_group.this["spoke"].name
  zone                            = "1"
  os_type                         = "Linux"
  sku_size                        = "Standard_D2s_v5"
  encryption_at_host_enabled      = true
  secure_boot_enabled             = true
  vtpm_enabled                    = true
  disable_password_authentication = true
  enable_telemetry                = var.enable_telemetry
  tags                            = local.tags

  account_credentials = {
    admin_credentials = {
      username                           = var.admin_username
      ssh_keys                           = [local.admin_ssh_public_key_effective]
      generate_admin_password_or_ssh_key = false
    }
    password_authentication_disabled = true
  }

  managed_identities = {
    system_assigned = true
  }

  network_interfaces = {
    primary = {
      name = "cfs-workload-nic-${local.region_code}"
      ip_configurations = {
        primary = {
          name                          = "ipconfig1"
          private_ip_subnet_resource_id = module.spoke_vnet.subnets["workload"].resource_id
          create_public_ip_address      = false
        }
      }
    }
  }

  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}
