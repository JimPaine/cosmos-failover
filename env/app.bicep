targetScope = 'resourceGroup'

param location string = resourceGroup().location
param compute_subnet_id string
param cosmos_uri string
param cosmos_db_name string
param cosmos_container_name string

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

resource app 'Microsoft.Web/sites@2022-03-01' = {
  name: 'app${suffix}'
  location: location

  identity: {
    type: 'SystemAssigned'
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
      ]
    }
  }
}

output app_principalId string = app.identity.principalId
output app_id string = app.id
