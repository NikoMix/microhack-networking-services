locals {
  region_code = "swc"

  tags = merge(
    {
      env      = "lab"
      workload = "cfs"
    },
    var.environment_tags
  )

  resource_groups = {
    hub   = "rg-cfs-hub-${local.region_code}"
    spoke = "rg-cfs-spoke-${local.region_code}"
    mgmt  = "rg-cfs-mgmt-${local.region_code}"
  }

  names = {
    law                 = "cfs-mgmt-law-${local.region_code}"
    hub_vnet            = "cfs-hub-vnet-${local.region_code}"
    spoke_vnet          = "cfs-app-vnet-${local.region_code}"
    workload_nsg        = "cfs-workload-nsg-${local.region_code}"
    workload_rt         = "cfs-workload-rt-${local.region_code}"
    firewall            = "cfs-hub-fw-${local.region_code}"
    firewall_policy     = "cfs-hub-fwpol-${local.region_code}"
    firewall_pip        = "cfs-fw-pip-${local.region_code}"
    bastion             = "cfs-hub-bas-${local.region_code}"
    bastion_pip         = "cfs-bas-pip-${local.region_code}"
    vpn_gateway         = "cfs-hub-vpngw-${local.region_code}"
    vpn_gateway_pip     = "cfs-vpngw-pip-${local.region_code}"
    key_vault           = "cfs-kv-${local.region_code}"
    storage_account     = "cfslabst${local.region_code}"
    vm                  = "cfs-workload-vm-${local.region_code}"
    load_balancer       = "cfs-internal-lb-${local.region_code}"
    app_gateway         = "cfs-appgw-${local.region_code}"
    app_gateway_pip     = "cfs-appgw-pip-${local.region_code}"
    app_gateway_waf     = "cfs-appgw-waf-${local.region_code}"
    front_door          = "cfs-afd-${local.region_code}"
    front_door_endpoint = "cfs-afd-ep-${local.region_code}"
    front_door_waf      = "cfs-afd-waf-${local.region_code}"
    network_watcher     = "cfs-nw-${local.region_code}"
  }

  private_dns_zones = {
    key_vault = "privatelink.vaultcore.azure.net"
    blob      = "privatelink.blob.core.windows.net"
  }

  admin_ssh_public_key_effective = var.admin_ssh_public_key != "" ? var.admin_ssh_public_key : tls_private_key.lab_admin.public_key_openssh
}
