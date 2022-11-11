targetScope = 'resourceGroup'

param location string = resourceGroup().location

resource workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'workspace'
  location: location

  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 90
  }
}

resource app_insights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appinsights'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspace.id
  }
}

output app_insights_key string = app_insights.properties.InstrumentationKey
output app_insights_connection_string string = app_insights.properties.ConnectionString
