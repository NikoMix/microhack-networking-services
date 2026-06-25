output "resource_group_names" {
  description = "CFS resource group names."
  value       = { for key, rg in azurerm_resource_group.this : key => rg.name }
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace resource ID."
  value       = module.log_analytics.resource_id
}

output "hub_vnet_id" {
  description = "Hub virtual network resource ID."
  value       = module.hub_vnet.resource_id
}

output "spoke_vnet_id" {
  description = "Spoke virtual network resource ID."
  value       = module.spoke_vnet.resource_id
}

output "azure_firewall_id" {
  description = "Azure Firewall resource ID."
  value       = module.azure_firewall.resource_id
}

output "bastion_id" {
  description = "Azure Bastion resource ID."
  value       = module.bastion.resource_id
}

output "vpn_gateway_id" {
  description = "VPN gateway resource ID when deployed."
  value       = var.deploy_vpn_gateway ? module.vpn_gateway[0].resource_id : null
}

output "key_vault_id" {
  description = "Key Vault resource ID."
  value       = module.key_vault.resource_id
}

output "key_vault_name" {
  description = "Key Vault name."
  value       = module.key_vault.name
}

output "storage_account_id" {
  description = "Storage account resource ID."
  value       = module.storage_account.resource_id
}

output "storage_account_name" {
  description = "Storage account name."
  value       = module.storage_account.name
}

output "linux_vm_id" {
  description = "Private Linux VM resource ID."
  value       = module.linux_vm.resource_id
}

output "internal_load_balancer_id" {
  description = "Internal Load Balancer resource ID."
  value       = module.internal_load_balancer.resource_id
}

output "application_gateway_id" {
  description = "Application Gateway resource ID."
  value       = module.application_gateway.resource_id
}

output "front_door_profile_id" {
  description = "Azure Front Door profile resource ID when deployed."
  value       = var.deploy_front_door ? module.front_door[0].resource_id : null
}

output "private_dns_zone_ids" {
  description = "Private DNS zone resource IDs."
  value = {
    key_vault = module.private_dns_key_vault.resource_id
    blob      = module.private_dns_blob.resource_id
  }
}

output "network_watcher_id" {
  description = "Network Watcher resource ID."
  value       = azurerm_network_watcher.this.id
}
