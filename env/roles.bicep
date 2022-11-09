targetScope = 'resourceGroup'

param cosmos_name string
param id string

resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2022-08-15' existing = {
  name: cosmos_name
}

// /subscriptions/2444dc94-61ad-4876-9ed2-c418539d817f/resourceGroups/cosmos-failover/providers/Microsoft.DocumentDB/databaseAccounts/cosmostgb7xg6nwcq2u/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002
resource ra 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2022-08-15' = {
  name: guid('sqlrole', subscription().id, resourceGroup().id, cosmos.id, id)

  parent: cosmos

  properties: {
    roleDefinitionId: '${cosmos.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002'
    principalId: id
    scope: cosmos.id
  }
}
