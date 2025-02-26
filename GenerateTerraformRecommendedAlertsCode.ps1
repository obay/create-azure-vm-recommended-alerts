<#
.SYNOPSIS
    Generates Terraform configuration files for recommended Azure VM alerts.

.DESCRIPTION
    This script creates Terraform module configurations for recommended alerts for Azure VMs in Production.
    It generates individual .tf files for each VM with alert configurations linked to a specified action group.

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

.EXAMPLE
    .\GenerateTerraformRecommendedAlertsCode.ps1 -AlertsResourceGroupName "monitoring-rg" -ActionGroupResourceGroupName "monitoring-rg" -ActionGroupName "monitoring-action-group" -TagKey "Environment" -TagValue "Production"

.NOTES
    Requires: Az PowerShell module
    Environment: Azure
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$AlertsResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$ActionGroupResourceGroupName,
    
    [Parameter(Mandatory=$true)]
    [string]$ActionGroupName,

    [Parameter(Mandatory=$true)]
    [string]$TagKey,

    [Parameter(Mandatory=$true)]
    [string]$TagValue
)

$actionGroupId = (Get-AzActionGroup -ResourceGroupName $ActionGroupResourceGroupName -Name $ActionGroupName).Id
$vmList = Get-AzVM -Status | Where-Object { $_.Tags[$TagKey] -eq $TagValue }
foreach ($vm in $vmList) {
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
}}
"@

    # Format the template
    $content = $template -f $vm.Name, $vm.Id, $AlertsResourceGroupName, $actionGroupId

    # Write content to file
    $content | Out-File -FilePath $fileName -Encoding UTF8
}

terraform fmt
# terraform init
# terraform validate
# terraform plan -out=plan.tfplan
# terraform apply plan.tfplan
