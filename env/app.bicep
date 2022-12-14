targetScope = 'resourceGroup'

param location string = resourceGroup().location
param compute_subnet_id string
param cosmos_uri string
param cosmos_db_name string
param cosmos_container_name string
param app_insights_key string
param app_insights_connection_string string

var suffix = uniqueString(subscription().id, resourceGroup().id)

resource farm 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: 'farm'
  location: location
  kind: 'linux'

  properties: {
    targetWorkerCount: 3
    targetWorkerSizeId: 3
    zoneRedundant: false
    reserved: true
  }
  sku: {
    tier: 'PremiumV2'
    name: 'P1v2'
  }
}

resource user_identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: 'app-msi-${suffix}'
  location: location
}

resource app 'Microsoft.Web/sites@2022-03-01' = {
  name: 'app${suffix}'
  location: location

  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${user_identity.id}' : {}
    }
  }

  properties: {
    serverFarmId: farm.id
    httpsOnly: true
    virtualNetworkSubnetId: compute_subnet_id

    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|6.0'
      alwaysOn: true
      ftpsState: 'Disabled'
      appSettings: [
        {
          name: 'COSMOS_URI'
          value: cosmos_uri
        }
        {
          name: 'COSMOS_DB_NAME'
          value: cosmos_db_name
        }
        {
          name: 'COSMOS_CONTAINER_NAME'
          value: cosmos_container_name
        }
        {
          name: 'DEPLOYED_REGION'
          value: location
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: app_insights_key
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: app_insights_connection_string
        }
        {
          name: 'USER_ASSIGNED_ID'
          value: user_identity.properties.clientId
        }
      ]
    }
  }
}

output app_principalId string = user_identity.properties.principalId
output app_id string = app.id
