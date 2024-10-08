param location string = resourceGroup().location
param env string
param supafanaDomain string
param supabaseProjectRef string
param supabaseProjectName string
param supabaseServiceRoleKey string
param smtpHost string
param smtpUser string
param smtpPassword string
param smtpFromAddress string
@secure()
param grafanaPassword string

param virtualNetworkName string = 'supafana-${env}-vnet'
//param apiSubnetName string = 'supafana-${env}-api-subnet'
param grafanaSubnetName string = 'supafana-${env}-grafana-subnet'

param commonResourceGroupName string = 'supafana-common-rg'
param imageGalleryName string = 'supafanasig'
param imageName string = 'grafana'
param imageVersion string = '0.0.13'

param projectId string = supabaseProjectRef

param vmName string = 'supafana-${env}-grafana-${supabaseProjectRef}'
param vmSize string = 'Standard_B2s'
param osDiskType string = 'Standard_LRS'
param osDiskSizeGB int = 20

var osDiskName = '${vmName}-os-disk'
var networkInterfaceName = '${vmName}-nic'

param privateDnsZoneName string = 'supafana-${env}.local'

var smtpFromName = 'Grafana alerts for ${supabaseProjectName}'

var customDataRaw = format('''
#cloud-config
write_files:
- content: |
    SUPABASE_PROJECT_REF={0}
    SUPABASE_SERVICE_ROLE_KEY={1}
    GF_SERVER_ROOT_URL=https://{3}/dashboard/{2}
    GF_SERVER_SERVE_FROM_SUB_PATH=true
    GRAFANA_PASSWORD={4}
    GF_SMTP_ENABLED=true
    GF_SMTP_HOST={5}
    GF_SMTP_USER={6}
    GF_SMTP_PASSWORD={7}
    GF_SMTP_FROM_ADDRESS={8}
    GF_SMTP_FROM_NAME={9}
    SUPABASE_PROJECT_NAME={10}
  path: /var/lib/supafana/supafana.env
''', supabaseProjectRef, supabaseServiceRoleKey, projectId, supafanaDomain, grafanaPassword, smtpHost, smtpUser, smtpPassword, smtpFromAddress, smtpFromName, supabaseProjectName)

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: virtualNetworkName
}
//var addressPrefix = vnet.properties.addressSpace.addressPrefixes[0]
var grafanaSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, grafanaSubnetName)
var tags = { vm: vmName }

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
            id: grafanaSubnetId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
  tags: tags
  dependsOn: [
    vnet
  ]
}

// Security group

// Image
resource image 'Microsoft.Compute/galleries/images/versions@2023-07-03' existing = {
  name: '${imageGalleryName}/${imageName}/${imageVersion}'
  scope: resourceGroup(commonResourceGroupName)
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
      adminPassword: 'Azurepass1349' //will be removed by nixos-rebuild
      customData: base64(customDataRaw)
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
  tags: tags
}

output privateIPAddress string = nic.properties.ipConfigurations[0].properties.privateIPAddress
output localDomain string = '${vmName}.${privateDnsZoneName}'
output publicUri string = 'https://${supafanaDomain}/dashboard/${projectId}'
