targetScope = 'resourceGroup'

param cosmos_name string
param id string

resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2022-08-15' existing = {
  name: cosmos_name
}

resource ra 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2022-08-15' = {
  name: 'dataContribRoleForApp'
  parent: cosmos

  properties: {
    roleDefinitionId: '${cosmos.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002'
    principalId: id
    scope: cosmos.id
  }
}
