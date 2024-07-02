@description('Supabase project id')
param supabaseProjectRef string

@description('Supabase role key')
param supabaseServiceRoleKey string

@description('Supafana domain')
param supafanaDomain string

@description('Supafana project id - will be used for routing')
param projectId string = supabaseProjectRef

@description('Vm image name')
param imageName string = 'grafana-v3'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The size of the VM.')
param vmSize string = 'Standard_B2s'

@description('Name of the VNET.')
param virtualNetworkName string = 'vNet'

@description('Subnet name')
param subnetName string = 'GrafanaSubnet'

@description('Name of the Network Security Group.')
param networkSecurityGroupName string = 'SecGroupNet'

@description('Local domain')
param privateDnsZoneName string = 'supafana.local'

var vmName = projectId
var networkInterfaceName = '${vmName}Nic'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var osDiskType = 'Standard_LRS'
var osDiskSizeGB = 20

var customDataRaw = format('''
#cloud-config
write_files:
- content: |
    SUPABASE_PROJECT_REF={0}
    SUPABASE_SERVICE_ROLE_KEY={1}
    GF_SERVER_ROOT_URL=https://{3}/dashboard/{2}
    GF_SERVER_SERVE_FROM_SUB_PATH=true
    GRAFANA_PASSWORD=hello
  path: /var/lib/supafana/supafana.env
''', supabaseProjectRef, supabaseServiceRoleKey, projectId, supafanaDomain)

// Public IP

resource publicIP 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: '${vmName}-ip'
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: 4
  }
  sku: {
    name: 'Standard'
  }
}

// Network interface
resource nic 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetRef
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

// Security group
resource nsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
           name: 'SSH'
           properties : {
               protocol : 'Tcp'
               sourcePortRange :  '*'
               destinationPortRange :  '22'
               sourceAddressPrefix :  '*'
               destinationAddressPrefix: '*'
               access:  'Allow'
               priority : 1010
               direction : 'Inbound'
               sourcePortRanges : []
               destinationPortRanges : []
               sourceAddressPrefixes : []
               destinationAddressPrefixes : []
          }
      }
      {
           name : 'Grafana'
           properties : {
               protocol :  'Tcp'
               sourcePortRange :  '*'
               destinationPortRange :  '8080'
               sourceAddressPrefix :  '*'
               destinationAddressPrefix :  '*'
               access :  'Allow'
               priority : 1030
               direction :  'Inbound'
               sourcePortRanges : []
               destinationPortRanges : []
               sourceAddressPrefixes : []
               destinationAddressPrefixes : []
          }
      }
      {
        name: 'Internal'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1040
          direction: 'Inbound'
        }
      }
    ]
  }
}

// Image

resource image 'Microsoft.Compute/images@2023-09-01' existing = {
  name: imageName
  scope: resourceGroup('MkImageResourceGroup')
}

// Virtual Machine
resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUserName: 'supafana'
      adminPassword: 'Azurepass1349' //will be removed by nixos-rebuild
      customData: base64(customDataRaw)
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
        diskSizeGB: osDiskSizeGB
      }
      imageReference: {
        id: image.id
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

output publicIPAddress string = publicIP.properties.ipAddress
output privateIPAddress string = nic.properties.ipConfigurations[0].properties.privateIPAddress
