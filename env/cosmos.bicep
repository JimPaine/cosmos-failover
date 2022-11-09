targetScope = 'resourceGroup'

param location string = resourceGroup().location

param regions array

var suffix = toLower(uniqueString(subscription().id,resourceGroup().id))

var locations = [for (region, index) in regions: {
    locationName: region
    failoverPriority: index
    isZoneRedundant: false
}]

resource account 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' = {
  name: 'cosmos${suffix}'
  location: location
  kind: 'GlobalDocumentDB'

  properties: {
    publicNetworkAccess: 'Disabled'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: locations
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: true
    enableMultipleWriteLocations: true
  }
}

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2022-05-15' = {
  name: 'database'
  parent: account

  properties: {
    resource: {
      id: 'database'
    }
  }
}

resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2022-08-15' = {
  name: 'container'
  parent: database

  properties: {
    resource: {
      id: 'container'
      partitionKey: {
        paths: [
          '/partionKey'
        ]
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/_etag/?'
          }
        ]
      }
    }
  }
}

output name string = account.name
output db_name string = database.name
output container_name string = container.name
