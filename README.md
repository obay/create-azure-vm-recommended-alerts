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

Make a copy of the terraform.tfvars.example file and name it terraform.tfvars:

```powershell
cp terraform.tfvars.example terraform.tfvars
```

Edit the terraform.tfvars file with your subscription id:

```powershell
subscription_id = "your-subscription-id"
```

Run the script:

```powershell
.\GenerateTerraformRecommendedAlertsCode.ps1 `
  -AlertsResourceGroupName "monitoring-rg" `
  -ActionGroupResourceGroupName "monitoring-rg" `
  -ActionGroupName "monitoring-action-group" `
  -TagKey "Environment" `
  -TagValue "Production" `
  -ClientId "your-client-id" `
  -ClientSecret "your-client-secret" `
  -TenantId "your-tenant-id"
```

### Required Parameters
- `AlertsResourceGroupName`: The name of the resource group where the alerts will be created.
- `ActionGroupResourceGroupName`: The name of the resource group where the action group exists.
- `ActionGroupName`: The name of the action group to use for the alerts.
- `TagKey`: The key of the tag to filter VMs.
- `TagValue`: The value of the tag to filter VMs.
- `ClientId`: The client ID of your Azure service principal.
- `ClientSecret`: The client secret of your Azure service principal.
- `TenantId`: Your Azure tenant ID.

### Optional Parameters
- `AvailableMemoryBytesThreshold`: The threshold for available memory bytes (default: 1000000000 bytes)
- `DataDiskIopsConsumedPercentageThreshold`: The threshold for data disk IOPS consumed percentage (default: 95)
- `MonitoringMetricAlertFrequency`: The frequency of the metric alert in minutes (default: 5)
- `MonitoringMetricAlertSeverity`: The severity of the metric alert (default: 3 - warning)
  - 0: Critical
  - 1: Error
  - 2: Informational
  - 3: Warning
- `MonitoringMetricAlertThreshold`: The threshold for the metric alert (default: 200000000000)
- `MonitoringMetricAlertWindowSize`: The window size of the metric alert in minutes (default: 5)
- `NetworkInTotalThreshold`: The threshold for network in total in bytes (default: 500000000000)
- `NetworkOutTotalThreshold`: The threshold for network out total in bytes (default: 200000000000)
- `OsDiskIopsConsumedPercentageThreshold`: The threshold for OS disk IOPS consumed percentage (default: 95)
- `PercentageCpuThreshold`: The threshold for percentage CPU (default: 80)

Example with optional parameters:
```powershell
.\GenerateTerraformRecommendedAlertsCode.ps1 `
  -AlertsResourceGroupName "monitoring-rg" `
  -ActionGroupResourceGroupName "monitoring-rg" `
  -ActionGroupName "monitoring-action-group" `
  -TagKey "Environment" `
  -TagValue "Production" `
  -ClientId "your-client-id" `
  -ClientSecret "your-client-secret" `
  -TenantId "your-tenant-id" `
  -PercentageCpuThreshold 90 `
  -MonitoringMetricAlertSeverity 2 `
  -AvailableMemoryBytesThreshold 2000000000
```

## How to deploy the Terraform code

Make sure you have the Terraform CLI installed:

```powershell
scoop install terraform
```

Initialize the Terraform code:

```powershell
terraform init
```

Plan the deployment:

```powershell
terraform plan -var-file="terraform.tfvars"
```

Install Azure CLI:

```powershell
scoop install azure-cli
```

Authenticate with Azure:

```powershell
az login
```

Apply the deployment:

```powershell
terraform apply -var-file="terraform.tfvars"
```


## How to delete the Terraform code

Delete the Terraform code:

```powershell
terraform destroy
```

## GitHub Actions Workflow Setup

This repository includes a GitHub Actions workflow for automated Terraform deployment. To use it, you need to set up the following:

### Required Secrets
Add these secrets to your GitHub repository (Settings > Secrets and variables > Actions):
- `AZURE_CLIENT_ID`: The client ID of your Azure service principal
- `AZURE_CLIENT_SECRET`: The client secret of your Azure service principal
- `AZURE_SUBSCRIPTION_ID`: Your Azure subscription ID
- `AZURE_TENANT_ID`: Your Azure tenant ID

### Required Variables
Add this variable to your GitHub repository (Settings > Environments > production > Variables):
- `TF_VAR_subscription_id`: Your Azure subscription ID (same as AZURE_SUBSCRIPTION_ID)

### Workflow Triggers
The workflow will run:
- On push to the main branch
- On pull requests
- Manually via workflow_dispatch

### What the Workflow Does
1. Sets up Azure credentials using the service principal
2. Initializes Terraform
3. Checks code formatting
4. Creates an execution plan
5. Applies the changes (only on push to main branch)
