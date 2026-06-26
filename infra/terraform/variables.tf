variable "location" {
  type        = string
  description = "Azure region for the lab. Defaults to Sweden Central; use westeurope as the fallback if Sweden Central is unavailable."
  default     = "swedencentral"
}

variable "environment_tags" {
  type        = map(string)
  description = "Additional tags merged with the mandatory CFS lab tags."
  default     = {}
}

variable "hub_address_space" {
  type        = list(string)
  description = "Address space for the hub virtual network."
  default     = ["10.0.0.0/16"]
}

variable "spoke_address_space" {
  type        = list(string)
  description = "Address space for the application spoke virtual network."
  default     = ["10.1.0.0/16"]
}

variable "admin_username" {
  type        = string
  description = "Linux VM local admin username for Bastion-based administration."
  default     = "azureuser"
}

variable "admin_ssh_public_key" {
  type        = string
  description = "Preferred SSH public key for the Linux VM. Leave empty to generate a lab key with tls_private_key; the private key is never output."
  default     = ""
  sensitive   = true
}

variable "deploy_vpn_gateway" {
  type        = bool
  description = "Deploy the route-based VPN virtual network gateway."
  default     = true
}

variable "deploy_front_door" {
  type        = bool
  description = "Deploy Azure Front Door Premium with WAF policy."
  default     = true
}

variable "budget_amount" {
  type        = number
  description = "Monthly CFS lab budget amount in the subscription currency."
  default     = 200
}

variable "budget_contact_emails" {
  type        = list(string)
  description = "Email recipients for budget alerts at 80% and 100%. Replace the example value before use."
  default     = ["cfs-networking-lab@example.invalid"]
}

variable "budget_start_date" {
  type        = string
  description = "Budget start date in RFC3339 format."
  default     = "2026-06-01T00:00:00Z"
}

variable "enable_telemetry" {
  type        = bool
  description = "Enable AVM module telemetry."
  default     = false
}
