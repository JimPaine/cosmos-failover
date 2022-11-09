targetScope = 'resourceGroup'

param location string = resourceGroup().location
param second_octet int
param cosmos_name string
param cosmos_group string

resource vnet 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: 'vnet'
  location: location

  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.${second_octet}.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'compute'
        properties: {
          addressPrefix: '10.${second_octet}.0.0/24'
          delegations: [
            {
              name: 'webapp'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: 'cosmos'
        properties: {
          addressPrefix: '10.${second_octet}.1.0/24'
          privateEndpointNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2022-08-15' existing = {
  name: cosmos_name
  scope: resourceGroup(cosmos_group)
}

resource endpoint 'Microsoft.Network/privateEndpoints@2022-05-01' = {
  name: 'cosmos-endpoint'
  location: location
  properties: {
    subnet: {
      id: vnet.properties.subnets[1].id
    }

    privateLinkServiceConnections: [
      {
        name: 'cosmos'
        properties: {
          privateLinkServiceId: cosmos.id
          groupIds: [
            'Sql'
          ]
        }
      }
    ]
  }
}

resource dns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.documents.azure.com'
  location: 'global'
}

resource link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'link'
  parent: dns
  location: 'global'
  properties: {
   registrationEnabled: false
   virtualNetwork: {
    id: vnet.id
   }
  }
}

resource dns_group 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-05-01' = {
  name: 'custom'
  parent: endpoint
  properties: {
   privateDnsZoneConfigs: [
    {
     name: 'config1'
     properties: {
      privateDnsZoneId: dns.id
     }
    }
   ]
  }
}

output cosmos_endpoints array = endpoint.properties.customDnsConfigs
output compute_subnet_id string = vnet.properties.subnets[0].id
output cosmos_uri string = dns_group.properties.privateDnsZoneConfigs[0].properties.recordSets[0].fqdn
