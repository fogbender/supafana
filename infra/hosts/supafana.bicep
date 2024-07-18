param location string = resourceGroup().location
param virtualNetworkName string = 'vNet'
param supafanaSubnetName string = 'SupafanaSubnet'

param imageResourceGroupName string = 'supafana-common-rg'
param imageGalleryName string = 'supafanasig'
param imageName string = 'supafana'
param imageVersion string = '0.0.1'

param vmName string = 'supafana'
param vmSize string = 'Standard_B2s'
param osDiskType string = 'Standard_LRS'
param osDiskSizeGB int = 20

var osDiskName = '${vmName}OSDisk'
var publicIPAddressName = '${vmName}PublicIP'
var networkInterfaceName = '${vmName}Nic'
var networkSecurityGroupName = '${vmName}SecGroupNet'

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: virtualNetworkName
}
var addressPrefix = vnet.properties.addressSpace.addressPrefixes[0]
var supafanaSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, supafanaSubnetName)

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
            id: supafanaSubnetRef
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
  dependsOn: [
    vnet
  ]
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
           name : 'HTTPS'
           properties : {
               protocol :  'Tcp'
               sourcePortRange :  '*'
               destinationPortRange :  '443'
               sourceAddressPrefix :  '*'
               destinationAddressPrefix :  '*'
               access :  'Allow'
               priority : 1020
               direction :  'Inbound'
               sourcePortRanges : []
               destinationPortRanges : []
               sourceAddressPrefixes : []
               destinationAddressPrefixes : []
          }
      }
      {
           name : 'HTTP'
           properties : {
               protocol :  'Tcp'
               sourcePortRange :  '*'
               destinationPortRange :  '80'
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
          sourceAddressPrefix: addressPrefix
          destinationAddressPrefix: addressPrefix
          access: 'Allow'
          priority: 1040
          direction: 'Inbound'
        }
      }
    ]
  }
}


// Public IP

resource publicIP 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: publicIPAddressName
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

// Image
resource image 'Microsoft.Compute/galleries/images/versions@2023-07-03' existing = {
  name: '${imageGalleryName}/${imageName}/${imageVersion}'
  scope: resourceGroup(imageResourceGroupName)
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
      adminUsername: 'supafana'
      adminPassword: 'Azurepass1349' //will be removed by nixos
    }
    storageProfile: {
      osDisk: {
        name: osDiskName
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
        diskSizeGB: osDiskSizeGB
        osType: 'Linux'
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
