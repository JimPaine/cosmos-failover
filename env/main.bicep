targetScope = 'subscription'

param default_location string = 'northeurope'

@description('A list of regions to deploy to, when a service requires primaries the assumption will be they are first in the array')
param regions array = [
  'North Europe'
  'West Europe'
]

var regions_lower_spaceless = [for region in regions: {
  value: replace(toLower(region), ' ', '')
}]

resource cosmos_group 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'cosmos-failover'
  location: default_location
}

resource groups 'Microsoft.Resources/resourceGroups@2021-04-01' = [for region in regions_lower_spaceless: {
  name: '${region.value}-cosmos-failover'
  location: region.value
}]

module insights 'insights.bicep' = [for (region, index) in regions_lower_spaceless: {
  name: '${region.value}-insights'
  scope: groups[index]
  params: {
    location: groups[index].location
  }
}]

module cosmos 'cosmos.bicep' = {
  name: 'cosmos'
  scope: cosmos_group
  params: {
    regions: regions
    location: default_location
  }
}

module networks 'networking.bicep' = [for (region, index) in regions_lower_spaceless: {
  name: '${region.value}-networking'
  scope: groups[index]
  params: {
    location: groups[index].location
    second_octet: index
    cosmos_name: cosmos.outputs.name
    cosmos_group: cosmos_group.name
  }
}]

module app 'app.bicep' = [for (region, index) in regions_lower_spaceless: {
  name: '${region.value}-app'
  scope: groups[index]
  params: {
    location: regions[index]
    compute_subnet_id: networks[index].outputs.compute_subnet_id
    cosmos_uri: networks[index].outputs.cosmos_uri
    cosmos_db_name: cosmos.outputs.db_name
    cosmos_container_name: cosmos.outputs.container_name
    app_insights_key: insights[index].outputs.app_insights_key
    app_insights_connection_string: insights[index].outputs.app_insights_connection_string
  }
}]

module role 'roles.bicep' = [for (region, index) in regions_lower_spaceless: {
  name: '${region.value}-app-cosmos-role'
  scope: cosmos_group

  params: {
    id: app[index].outputs.app_principalId
    cosmos_name: cosmos.outputs.name
  }
}]

output apps array = [for index in range(0, length(regions)): {
  id: app[index].outputs.app_id
}]
