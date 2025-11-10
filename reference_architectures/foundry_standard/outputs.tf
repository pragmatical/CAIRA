# ---------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. Licensed under the MIT license.
# ---------------------------------------------------------------------

output "ai_foundry_id" {
  description = "The resource ID of the AI Foundry account."
  value       = module.ai_foundry.ai_foundry_id
}

output "ai_foundry_name" {
  description = "The name of the AI Foundry account."
  value       = module.ai_foundry.ai_foundry_name
}

output "ai_foundry_default_project_id" {
  description = "The resource ID of the AI Foundry default project when the projects collection length is 1 and matches the default object. Otherwise, null."
  value       = length(module.projects) == 1 ? values({ for k, m in module.projects : k => m.ai_foundry_project_id })[0] : null
}

output "ai_foundry_default_project_name" {
  description = "The name of the AI Foundry default project when the projects collection length is 1 and matches the default object. Otherwise, null."
  value       = length(module.projects) == 1 ? values({ for k, m in module.projects : k => m.ai_foundry_project_name })[0] : null
}

output "ai_foundry_default_project_identity_principal_id" {
  description = "The principal ID of the AI Foundry default project's system-assigned managed identity when the projects collection length is 1. Otherwise, null."
  value       = length(module.projects) == 1 ? values({ for k, m in module.projects : k => m.ai_foundry_project_identity_principal_id })[0] : null
}

# Aggregated multi-project outputs
output "ai_foundry_projects" {
  description = "Map of AI Foundry project metadata keyed by project_name. Empty map if no projects deployed (when var.projects = [])."
  value = { for k, m in module.projects : k => {
    id                    = m.ai_foundry_project_id
    name                  = m.ai_foundry_project_name
    identity_principal_id = m.ai_foundry_project_identity_principal_id
  } }
}

output "ai_foundry_project_ids" {
  description = "Map of AI Foundry project IDs keyed by project_name. Empty map if no projects deployed."
  value       = { for k, m in module.projects : k => m.ai_foundry_project_id }
}

output "ai_foundry_model_deployments_ids" {
  description = "The IDs of the AI Foundry model deployments."
  value       = module.ai_foundry.ai_foundry_model_deployments_ids
}

output "resource_group_id" {
  description = "The resource ID of the resource group."
  value       = local.resource_group_resource_id
}

output "resource_group_name" {
  description = "The name of the resource group."
  value       = local.resource_group_name
}

output "ai_foundry_endpoint" {
  description = "The endpoint URL of the AI Foundry account."
  value       = module.ai_foundry.ai_foundry_endpoint
}

output "agent_capability_host_connections_1" {
  description = "The connections used for the agent capability host."
  value       = module.capability_host_resources_1.connections
}

output "application_insights_id" {
  description = "The resource ID of the Application Insights instance."
  value       = module.application_insights.resource_id
}

output "log_analytics_workspace_id" {
  description = "The resource ID of the Log Analytics workspace."
  value       = azurerm_log_analytics_workspace.this.id
}
