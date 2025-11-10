# ---------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. Licensed under the MIT license.
# ---------------------------------------------------------------------

locals {
  # Create unique connection names by appending project name to resource name
  # This allows multiple projects to share the same physical resources
  cosmos_connection_name  = var.agent_capability_host_connections != null ? "${var.agent_capability_host_connections.cosmos_db.name}-${var.project_name}" : null
  storage_connection_name = var.agent_capability_host_connections != null ? "${var.agent_capability_host_connections.storage_account.name}-${var.project_name}" : null
  search_connection_name  = var.agent_capability_host_connections != null ? "${var.agent_capability_host_connections.ai_search.name}-${var.project_name}" : null
}

# Connection to Cosmos DB
resource "azapi_resource" "cosmosdb_connection" {
  count = var.agent_capability_host_connections != null ? 1 : 0

  type                      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
  name                      = local.cosmos_connection_name
  parent_id                 = azapi_resource.ai_foundry_project.id
  schema_validation_enabled = false

  depends_on = [
    azapi_resource.ai_foundry_project
  ]

  body = {
    name = local.cosmos_connection_name
    properties = {
      category = "CosmosDb"
      target   = var.agent_capability_host_connections.cosmos_db.endpoint
      authType = "AAD"
      metadata = {
        ApiType    = "Azure"
        ResourceId = var.agent_capability_host_connections.cosmos_db.resource_id
        location   = var.location
      }
    }
  }

}

# Connection to Storage Account
resource "azapi_resource" "storage_connection" {
  count = var.agent_capability_host_connections != null ? 1 : 0

  type                      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
  name                      = local.storage_connection_name
  parent_id                 = azapi_resource.ai_foundry_project.id
  schema_validation_enabled = false

  depends_on = [
    azapi_resource.ai_foundry_project
  ]

  body = {
    name = local.storage_connection_name
    properties = {
      category = "AzureStorageAccount"
      target   = var.agent_capability_host_connections.storage_account.primary_blob_endpoint
      authType = "AAD"
      metadata = {
        ApiType    = "Azure"
        ResourceId = var.agent_capability_host_connections.storage_account.resource_id
        location   = var.location
      }
    }
  }

  response_export_values = [
    "identity.principalId"
  ]
}

# Connection to AI Search
resource "azapi_resource" "ai_search_connection" {
  count = var.agent_capability_host_connections != null ? 1 : 0

  type                      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
  name                      = local.search_connection_name
  parent_id                 = azapi_resource.ai_foundry_project.id
  schema_validation_enabled = false

  depends_on = [
    azapi_resource.ai_foundry_project
  ]

  body = {
    name = local.search_connection_name
    properties = {
      category = "CognitiveSearch"
      target   = "https://${var.agent_capability_host_connections.ai_search.name}.search.windows.net"
      authType = "AAD"
      metadata = {
        ApiType    = "Azure"
        ApiVersion = "2025-05-01-preview"
        ResourceId = var.agent_capability_host_connections.ai_search.resource_id
        location   = var.location
      }
    }
  }

  response_export_values = [
    "identity.principalId"
  ]
}

# Optional destroy delay for AI Search connection
resource "time_sleep" "ai_search_connection_destroy_delay" {
  destroy_duration = "60s"

  # Ensure the connection is created before we can register this artificial dependency
  depends_on = [azapi_resource.ai_search_connection]
}

# Capability host for AI Foundry Agents
resource "azapi_resource" "ai_foundry_project_capability_host" {
  count = var.agent_capability_host_connections != null ? 1 : 0

  replace_triggers_external_values = var.agent_capability_host_connections

  depends_on = [
    azapi_resource.cosmosdb_connection,
    azapi_resource.storage_connection,
    azapi_resource.ai_search_connection,
    time_sleep.ai_search_connection_destroy_delay,

    time_sleep.wait_rbac
  ]
  type                      = "Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2025-04-01-preview"
  name                      = "agents-capability-host"
  parent_id                 = azapi_resource.ai_foundry_project.id
  schema_validation_enabled = false

  body = {
    properties = {
      capabilityHostKind = "Agents"

      vectorStoreConnections = [
        local.search_connection_name
      ]

      storageConnections = [
        local.storage_connection_name
      ]

      threadStorageConnections = [
        local.cosmos_connection_name
      ]
    }
  }
}
