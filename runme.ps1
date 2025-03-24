$ClientId = get-content "sp_credentials.json" | ConvertFrom-Json | Select-Object -ExpandProperty clientId
$ClientSecret = get-content "sp_credentials.json" | ConvertFrom-Json | Select-Object -ExpandProperty clientSecret
$TenantId = get-content "sp_credentials.json" | ConvertFrom-Json | Select-Object -ExpandProperty tenantId
$ActionGroupSubscriptionId = (Get-AzContext).Subscription.Id
$AlertsResourceGroupName = "monitoring-rg"
$ActionGroupResourceGroupName = "monitoring-rg"
$ActionGroupName = "monitoring-action-group"
$TagKey = "Environment"
$TagValue = "Production"

.\2.GenerateTerraformRecommendedAlertsCode.ps1 -AlertsResourceGroupName $AlertsResourceGroupName -ActionGroupResourceGroupName $ActionGroupResourceGroupName -ActionGroupName $ActionGroupName -TagKey $TagKey -TagValue $TagValue -ClientId $ClientId -ClientSecret $ClientSecret -TenantId $TenantId -ActionGroupSubscriptionId $ActionGroupSubscriptionId