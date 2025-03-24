<#
.SYNOPSIS
    Generates Terraform configuration files for recommended Azure VM alerts.

.DESCRIPTION
    This script creates Terraform module configurations for recommended alerts for Azure VMs in Production.
    It generates individual .tf files for each VM with alert configurations linked to a specified action group.
    The script iterates through all accessible subscriptions.

.PARAMETER AlertsResourceGroupName
    The name of the resource group where the alerts will be created.

.PARAMETER ActionGroupResourceGroupName
    The name of the resource group where the action group exists.

.PARAMETER ActionGroupName
    The name of the action group to use for the alerts.

.PARAMETER TagKey
    The key of the tag to filter VMs.

.PARAMETER TagValue
    The value of the tag to filter VMs.

.PARAMETER ActionGroupSubscriptionId
    The ID of the subscription containing the action group.

.PARAMETER ClientId
    The client ID for the service principal.

.PARAMETER ClientSecret
    The client secret for the service principal.

.PARAMETER TenantId
    The tenant ID for the service principal.

.PARAMETER AvailableMemoryBytesThreshold
    The threshold for available memory bytes.

.PARAMETER DataDiskIopsConsumedPercentageThreshold
    The threshold for data disk IOPS consumed percentage.

.PARAMETER MonitoringMetricAlertFrequency
    The frequency for monitoring metric alerts.

.PARAMETER MonitoringMetricAlertSeverity
    The severity for monitoring metric alerts.

.PARAMETER MonitoringMetricAlertThreshold
    The threshold for monitoring metric alerts.

.PARAMETER MonitoringMetricAlertWindowSize
    The window size for monitoring metric alerts.

.PARAMETER NetworkInTotalThreshold
    The threshold for network in total.

.PARAMETER NetworkOutTotalThreshold
    The threshold for network out total.

.PARAMETER OsDiskIopsConsumedPercentageThreshold
    The threshold for OS disk IOPS consumed percentage.

.PARAMETER PercentageCpuThreshold
    The threshold for percentage CPU.

.EXAMPLE
    .\GenerateTerraformRecommendedAlertsCode.ps1 -AlertsResourceGroupName "monitoring-rg" -ActionGroupResourceGroupName "monitoring-rg" -ActionGroupName "monitoring-action-group" -TagKey "Environment" -TagValue "Production" -ClientId "00000000-0000-0000-0000-000000000000" -ClientSecret "your-client-secret" -TenantId "11111111-1111-1111-1111-111111111111"

.NOTES
    Requires: Az PowerShell module
    Environment: Azure
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ActionGroupName,

    [Parameter(Mandatory=$true)]
    [string]$ActionGroupResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$ActionGroupSubscriptionId,
    
    [Parameter(Mandatory=$true)]
    [string]$AlertsResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$TagKey,

    [Parameter(Mandatory=$true)]
    [string]$TagValue,

    [Parameter(Mandatory=$true)]
    [string]$ClientId,

    [Parameter(Mandatory=$true)]
    [string]$ClientSecret,

    [Parameter(Mandatory=$true)]
    [string]$TenantId,

    [Parameter(Mandatory=$false)]
    [int]$AvailableMemoryBytesThreshold = 1000000000,

    [Parameter(Mandatory=$false)]
    [int]$DataDiskIopsConsumedPercentageThreshold = 95,

    [Parameter(Mandatory=$false)]
    [int]$MonitoringMetricAlertFrequency = 5,

    [Parameter(Mandatory=$false)]
    [int]$MonitoringMetricAlertSeverity = 3,

    [Parameter(Mandatory=$false)]
    [int]$MonitoringMetricAlertThreshold = 200000000000,

    [Parameter(Mandatory=$false)]
    [int]$MonitoringMetricAlertWindowSize = 5,

    [Parameter(Mandatory=$false)]
    [int]$NetworkInTotalThreshold = 500000000000,

    [Parameter(Mandatory=$false)]
    [int]$NetworkOutTotalThreshold = 200000000000,

    [Parameter(Mandatory=$false)]
    [int]$OsDiskIopsConsumedPercentageThreshold = 95,

    [Parameter(Mandatory=$false)]
    [int]$PercentageCpuThreshold = 80
)

# Login using a service principal
$credential = New-Object System.Management.Automation.PSCredential($ClientId, (ConvertTo-SecureString $ClientSecret -AsPlainText -Force))
Connect-AzAccount -ServicePrincipal -Tenant $TenantId -Credential $credential

# Get all subscriptions
$subscriptions = Get-AzSubscription

# First, get the action group ID from the specified subscription
$actionGroupId = $null
try {
    # Set context to the subscription containing the action group
    Set-AzContext -Subscription $ActionGroupSubscriptionId | Out-Null

    # Get the action group ID
    $actionGroupId = (Get-AzActionGroup -ResourceGroupName $ActionGroupResourceGroupName -Name $ActionGroupName).Id
    
    if ([string]::IsNullOrEmpty($actionGroupId)) {
        throw "Action group ID is null or empty for group '$ActionGroupName' in resource group '$ActionGroupResourceGroupName'"
    }
}
catch {
    Write-Error "Failed to get action group ID: $_"
    exit 1
}

# Now iterate through all subscriptions for VM processing
foreach ($subscription in $subscriptions) {
    Write-Host "Processing subscription: $($subscription.Name)"
    
    # Set the context to the current subscription
    Set-AzContext -Subscription $subscription.Id | Out-Null
    
    try {
        # Get VMs with matching tags in the current subscription
        $vmList = Get-AzVM -Status | Where-Object { $_.Tags[$TagKey] -eq $TagValue }
        
        foreach ($vm in $vmList) {
            Write-Host "Generating alert configuration for VM: $($vm.Name)"
            
            # Create the filename using the specified pattern
            $fileName = "module.$($vm.Name)-recommended-alerts.tf"
            
            # Define the template with placeholders
            $template = @"
module "{0}-recommended-alerts" {{
  source                              = "obay/recommended-alerts/azurerm"
  version                             = "0.0.7"
  vmname                              = "{0}"
  monitoring_scope                    = "{1}"
  monitoring_resource_group_name      = "{2}"
  monitoring_action_group_id          = "{3}"
  available_memory_bytes_threshold    = {4}
  data_disk_iops_consumed_percentage_threshold = {5}
  monitoring_metric_alert_frequency   = {6}
  monitoring_metric_alert_severity    = {7}
  monitoring_metric_alert_threshold   = {8}
  monitoring_metric_alert_window_size = {9}
  network_in_total_threshold          = {10}
  network_out_total_threshold         = {11}
  os_disk_iops_consumed_percentage_threshold = {12}
  percentage_cpu_threshold            = {13}
}}
"@

            # Format the template
            $content = $template -f $vm.Name, $vm.Id, $AlertsResourceGroupName, $actionGroupId,
                      $AvailableMemoryBytesThreshold,
                      $DataDiskIopsConsumedPercentageThreshold,
                      $MonitoringMetricAlertFrequency,
                      $MonitoringMetricAlertSeverity,
                      $MonitoringMetricAlertThreshold,
                      $MonitoringMetricAlertWindowSize,
                      $NetworkInTotalThreshold,
                      $NetworkOutTotalThreshold,
                      $OsDiskIopsConsumedPercentageThreshold,
                      $PercentageCpuThreshold

            # Write content to file
            $content | Out-File -FilePath $fileName -Encoding UTF8
        }
    }
    catch {
        Write-Warning "Error processing subscription $($subscription.Name): $_"
        continue
    }
}

terraform fmt
