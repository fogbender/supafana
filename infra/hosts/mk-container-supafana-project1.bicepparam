using './container-supafana.bicep'

param project = 'project1'
param image = 'supafanastgcr.azurecr.io/supafana-image:2024.6.3'
param acrName = 'supafanastgcr'
param acrResourceGroupName = 'supafanaStageResourceGroup'

param supabaseProjectRef = 'qlsuulkvgexqylfezivg'
param supabaseServiceRoleKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFsc3V1bGt2Z2V4cXlsZmV6aXZnIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcxODIwODY5NCwiZXhwIjoyMDMzNzg0Njk0fQ.LLSQrKBJeCeZzq01ezNCLVUVJysdpB09bK9qFqnZc70'
param grafanaUrl = 'https://supafana.com'
param grafanaPassword = 'hello'
