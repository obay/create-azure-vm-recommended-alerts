<#
.SYNOPSIS
Creates an Azure Service Principal with specified role assignments for GitHub Actions authentication.

.DESCRIPTION
This script creates a new Azure Service Principal and configures it with the specified role (default: Contributor)
for use with GitHub Actions. It generates the necessary credentials and saves them in a JSON format that is
compatible with GitHub Actions' Azure login action. The Service Principal is assigned the specified role at the
root management group level, giving it access across all subscriptions under the management group hierarchy.

.PARAMETER ServicePrincipalName
The display name for the new Service Principal. 
Default value: "github-actions-sp"

.PARAMETER RoleName
The Azure RBAC role to assign to the Service Principal at the root management group level.
Default value: "Contributor"

.PARAMETER OutputPath
The file path where the Service Principal credentials will be saved in JSON format.
Default value: "sp_credentials.json"

.EXAMPLE
.\CreateSP.ps1

.EXAMPLE
.\CreateSP.ps1 -ServicePrincipalName "my-custom-sp" -RoleName "Reader" -OutputPath "my-credentials.json"

.NOTES
Prerequisites:
- Azure PowerShell (Az) module must be installed
- User must be connected to Azure (Connect-AzAccount)
- User must have sufficient permissions to:
  * Create Service Principals
  * Assign roles at the root management group level
  * Read management group information

.LINK
https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ServicePrincipalName = "github-actions-sp",

    [Parameter(Mandatory = $false)]
    [string]$RoleName = "Contributor",

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "sp_credentials.json"
)

# Ensure the Az module is installed and imported
if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
    Write-Error "Az PowerShell module is not installed. Please install it using: Install-Module -Name Az -Force -AllowClobber"
    exit 1
}

try {
    # Ensure we're connected to Azure
    $context = Get-AzContext
    if (-not $context) {
        Write-Error "Not connected to Azure. Please run Connect-AzAccount first."
        exit 1
    }

    # Get the root management group
    try {
        # First get all management groups
        $allMGs = Get-AzManagementGroup
        
        # Then get details of each to find the root (tenant root group has no parent)
        foreach ($mg in $allMGs) {
            $mgDetails = Get-AzManagementGroup -GroupId $mg.Name -Expand
            if ([string]::IsNullOrEmpty($mgDetails.ParentId)) {
                $rootMG = $mgDetails
                break
            }
        }
        
        if (-not $rootMG) {
            Write-Error "Unable to find root management group. Please ensure you have necessary permissions."
            exit 1
        }
    }
    catch {
        Write-Error "Failed to get root management group. Error: $_"
        exit 1
    }

    Write-Host "Found root management group: $($rootMG.DisplayName) ($($rootMG.Name))"

    # Create service principal
    $sp = New-AzADServicePrincipal -DisplayName $ServicePrincipalName

    # Create a new password for the service principal
    $spPassword = New-AzADSpCredential -ObjectId $sp.Id -EndDate (Get-Date).AddYears(2)

    # Assign role at root management group level
    $roleAssignment = New-AzRoleAssignment -ApplicationId $sp.AppId `
        -RoleDefinitionName $RoleName `
        -Scope "/providers/Microsoft.Management/managementGroups/$($rootMG.Name)"

    Write-Host "Assigned role '$RoleName' at root management group scope"

    # Create the output object in the format expected by GitHub Actions
    $output = @{
        clientId                = $sp.AppId
        clientSecret           = $spPassword.SecretText
        tenantId              = $context.Tenant.Id
        activeDirectoryEndpointUrl = "https://login.microsoftonline.com"
        resourceManagerEndpointUrl = "https://management.azure.com/"
        activeDirectoryGraphResourceId = "https://graph.windows.net/"
        sqlManagementEndpointUrl = "https://management.core.windows.net:8443/"
        galleryEndpointUrl       = "https://gallery.azure.com/"
        managementEndpointUrl    = "https://management.core.windows.net/"
    }

    # Convert to JSON and save to file
    $output | ConvertTo-Json | Set-Content -Path $OutputPath

    Write-Host "Service Principal created successfully!"
    Write-Host "Credentials saved to: $OutputPath"
    Write-Host "Service Principal Name: $ServicePrincipalName"
    Write-Host "Service Principal ID: $($sp.AppId)"
    Write-Host "Tenant ID: $($context.Tenant.Id)"

} catch {
    Write-Error "An error occurred: $_"
    exit 1
}