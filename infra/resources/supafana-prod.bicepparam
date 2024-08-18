using '../modules/supafana.bicep'

param env = 'prod'
param adminGroupName = 'SupafanaProdAdmins'
param publicDomain = 'supafana.com'

param apiVmSize = 'Standard_D4s_v4'
param apiOsDiskType = 'PremiumV2_LRS'
param apiOsDiskSizeGB = 100

param dbVersion  = '15'
param dbSkuName  = 'Standard_D4ds_v4'
param dbSkuTier  = 'GeneralPurpose'
param dbDiskSizeGb = 128
