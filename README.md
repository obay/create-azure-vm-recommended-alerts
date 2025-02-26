# Virtual Machine Recommended Alerts Terraform Generator

This project generates Terraform code for recommended alerts for Azure Virtual Machines and Azure Virtual Machine Scale Sets.

The script will list all the VMs and VMSS in the subscription and filter them based on the tag key and value and then generate the Terraform code to create the recommended alerts in Azure Monitor.

## How to use

Clone the repository:

```powershell
git clone https://github.com/obay/create-azure-vm-recommended-alerts.git
```

Make sure you have the Azure PowerShell module installed:

```powershell
Install-Module -Name Az
```

Authenticate with Azure:

```powershell
Connect-AzAccount
```

Run the script:

```powershell
.\GenerateTerraformRecommendedAlertsCode.ps1 -AlertsResourceGroupName "monitoring-rg" -ActionGroupResourceGroupName "monitoring-rg" -ActionGroupName "monitoring-action-group" -TagKey "Environment" -TagValue "Production"
```



