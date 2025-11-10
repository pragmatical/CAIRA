# ---------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. Licensed under the MIT license.
# ---------------------------------------------------------------------

############################################################
# Foundry Standard Reference Architecture - Root Module Call
#
# This Terraform stack provisions a baseline Azure AI Foundry
# environment with data sovereignty and resource compliance
# support.
############################################################

# Reusable model definitions used when configuring AI Foundry
# (exposes typed outputs for common model deployments)
module "common_models" {
  source = "../../modules/common_models"
}

# Azure naming convention helper to generate consistent and
# unique resource names across subscriptions and regions.
module "naming" {
  # https://registry.terraform.io/modules/Azure/naming/azurerm/latest
  source        = "Azure/naming/azurerm"
  version       = "0.4.2"
  suffix        = [local.base_name] # Suffix ensures uniqueness while keeping a human-friendly base name
  unique-length = 5                 # Number of random characters appended to resource names
}

# Resource Group (conditionally created)
# If an existing resource group ID is not provided, create one using the
# generated name from the naming module.
resource "azurerm_resource_group" "this" {
  count    = var.resource_group_resource_id == null ? 1 : 0
  location = var.location
  name     = module.naming.resource_group.name_unique
  tags     = var.tags
}

# Local values centralize the computed naming and resource group id.
locals {
  base_name                  = "standard" # Used as the semantic prefix for naming resources
  resource_group_resource_id = var.resource_group_resource_id != null ? var.resource_group_resource_id : azurerm_resource_group.this[0].id
  resource_group_name        = var.resource_group_resource_id != null ? provider::azapi::parse_resource_id("Microsoft.Resources/resourceGroups", var.resource_group_resource_id).resource_group_name : azurerm_resource_group.this[0].name

  # Select raw models: user override or defaults. Using try() to handle null gracefully.
  # Using currently available models (gpt-4o variants) instead of future-dated models.
  raw_model_deployments = try(var.model_deployments, [
    module.common_models.gpt_4o,
    module.common_models.gpt_4o_mini,
    module.common_models.text_embedding_3_large
  ])

  # Normalize each object to guarantee presence of sku attribute.
  normalized_model_deployments = [for d in local.raw_model_deployments : merge(d, {
    sku = lookup(d, "sku", null) != null ? d.sku : {
      name     = "GlobalStandard"
      capacity = 1
    }
  })]
}

# Core AI Foundry environment module
module "ai_foundry" {
  source = "../../modules/ai_foundry"

  # Target resource group and region
  resource_group_id = local.resource_group_resource_id
  location          = var.location

  sku = var.sku # AI Foundry SKU/tier

  # Logical name used for AI Foundry and dependent resources
  name = module.naming.cognitive_account.name_unique

  # Model deployments to make available within Foundry
  # Add/remove models as needed for your workload requirements
  # Use override list if non-empty; otherwise default models.
  model_deployments = local.normalized_model_deployments

  application_insights = module.application_insights

  tags = var.tags
}

# Shared capability host resources for all projects.
# Single set of Cosmos DB, Storage, and AI Search resources.
module "capability_host_resources" {
  source = "../../modules/new_resources_agent_capability_host_connections"

  location                   = var.location
  resource_group_resource_id = local.resource_group_resource_id
  tags                       = var.tags

  cosmos_db_account_name = module.naming.cosmosdb_account.name_unique
  storage_account_name   = module.naming.storage_account.name_unique
  ai_search_name         = module.naming.search_service.name_unique
}

# AI Foundry projects (collection-driven). All projects share the same capability host resources.
# Connection names are automatically made unique per project by the ai_foundry_project module.
module "projects" {
  for_each   = { for p in var.projects : p.project_name => p }
  source     = "../../modules/ai_foundry_project"
  depends_on = [module.ai_foundry, module.capability_host_resources]

  location             = var.location
  ai_foundry_id        = module.ai_foundry.ai_foundry_id
  project_name         = each.value.project_name
  project_display_name = each.value.project_display_name
  project_description  = each.value.project_description

  agent_capability_host_connections = module.capability_host_resources.connections
  tags                              = var.tags
}
