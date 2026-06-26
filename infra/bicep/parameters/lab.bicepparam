// Lab parameters for the CFS secure hub & spoke landing zone.
// Pupils copy/adjust this file. No secrets here — SSH key + emails are non-secret inputs.
using '../main.bicep'

param location = 'swedencentral'
param regionToken = 'swc'
param namePrefix = 'cfs'
param environmentName = 'lab'

// Toggle the slow / costly resources off for fast validation runs if desired.
param deployVpnGateway = true
param deployFrontDoor = true
param deployNetworkWatcher = true

param adminUsername = 'cfsadmin'
// Paste an OpenSSH public key to enable the private VM (password auth is disabled).
param adminSshPublicKey = ''
param vmSize = 'Standard_D2s_v5'

// Cost guardrail — supply at least one email to create the budget + alerts.
param budgetAmount = 200
param budgetContactEmails = []
param budgetStartDate = '2026-06-01'
