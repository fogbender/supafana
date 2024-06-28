@description('Supafana project id')
param projectId string = 'grafana1'

@description('Vm image name')
param imageName string = 'grafana-v1'

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

var customDataRaw = '''
#cloud-config

write_files:
- content: AUFZJWFoiO+e2OtOA4W1iHA3Spah9jGOx8VKVt6+iO+ACRA0O/J0
  path: /var/lib/supafana/registry-pass.txt
  owner: supafana:supafana
  defer: true
- content: |
    SUPABASE_PROJECT_REF=qlsuulkvgexqylfezivg
    SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsc3V1bGt2Z2V4cXlsZmV6aXZnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcxODIwODY5NCwiZXhwIjoyMDMzNzg0Njk0fQ.LLSQrKBJeCeZzq01ezNCLVUVJysdpB09bK9qFqnZc70
    GRAFANA_URL=supafana.com
    GRAFANA_PASSWORD=hello
  path: /var/lib/supafana/supafana.env
  defer: true
'''

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
