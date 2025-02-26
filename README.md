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
.\GenerateTerraformRecommendedAlertsCode.ps1 -AlertsResourceGroupName "monitoring-rg" -ActionGroupResourceGroupName "monitoring-rg" -ActionGroupName "monitoring-action-group" -TagKey "Environment" -TagValue "Production"
```

- AlertsResourceGroupName: The name of the resource group where the alerts will be created.
- ActionGroupResourceGroupName: The name of the resource group where the action group exists.
- ActionGroupName: The name of the action group to use for the alerts.
- TagKey: The key of the tag to filter VMs.
- TagValue: The value of the tag to filter VMs.

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

Apply the deployment:

```powershell
terraform apply -var-file="terraform.tfvars"
```


## How to delete the Terraform code

Delete the Terraform code:

```powershell
terraform destroy
```
