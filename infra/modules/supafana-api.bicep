param location string = resourceGroup().location
param env string
param publicDomain string
param vnetId string
param apiSubnetId string
param keyVaultName string
param dbHostName string

param vmName string = 'supafana-${env}-api'
param vmSize string = 'Standard_B2s'
param osDiskType string = 'Standard_LRS'
param osDiskSizeGB int = 20
param imageVersion string = '0.0.2'

param commonResourceGroupName string = 'supafana-common-rg'
param imageGalleryName string = 'supafanasig'
param imageName string = 'supafana'

var osDiskName = '${vmName}-os-disk'
var publicIPAddressName = '${vmName}-public-ip'
var networkInterfaceName = '${vmName}-nic'
var networkSecurityGroupName = '${vmName}-nsg'

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
            id: apiSubnetId
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
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
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
        name: 'MOSH'
        properties : {
          protocol : 'Udp'
          sourcePortRange :  '*'
          destinationPortRange :  '60000-61000'
          sourceAddressPrefix :  '*'
          destinationAddressPrefix: '*'
          access:  'Allow'
          priority : 1050
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
  scope: resourceGroup(commonResourceGroupName)
}

// Virtual Machine
resource vm 'Microsoft.Compute/virtualMachines@2024-07-11' = {
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
  identity: {
    type: 'SystemAssigned'
  }
}

module dnsRecord './public-dns-record.bicep' = {
  name: 'dns-record'
  params: {
    ipAddress: publicIP.properties.ipAddress
    publicDomain: publicDomain
  }
  scope: resourceGroup(commonResourceGroupName)
}

module keyRoleAssignment './key-vault-role.bicep' = {
  name: 'role-assignment'
  params: {
    keyVaultName: keyVaultName
    roleName: 'Key Vault Crypto User'
    principalId: vm.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

module vmContributorRole './group-role.bicep' = {
  name: 'vm-contributor-role'
  scope: resourceGroup()
  params: {
    roleName: 'Virtual Machine Contributor'
    principalId: vm.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

module templateSpecReaderRole './sub-role.bicep' = {
  name: 'template-spec-reader-role'
  scope: subscription()
  params: {
    roleName: 'Template Spec Reader'
    principalId: vm.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

module imageReaderRole './sub-role.bicep' = {
  name: 'image-reader-role'
  scope: subscription()
  params: {
    roleName: 'supafana-sig-access'
    principalId: vm.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

module dbAdmin './db-admin.bicep' = {
  name: 'db-admin-module'
  params: {
    dbName: dbHostName
    principalType: 'ServicePrincipal'
    principalName: vmName
    principalId: vm.identity.principalId
  }
}

output publicIPAddress string = publicIP.properties.ipAddress
output privateIPAddress string = nic.properties.ipConfigurations[0].properties.privateIPAddress
