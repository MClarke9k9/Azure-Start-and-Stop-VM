# Resource Creation

## Overview

This folder contains the Terraform configuration used to create the Azure infrastructure for the VM Start/Stop project.

Terraform creates:

- Two Azure Function Apps
- One Flex Consumption App Service Plan
- Two Ubuntu Linux Virtual Machines
- Virtual Network and Subnet
- Network Security Group allowing SSH
- Public IP addresses
- Network Interfaces
- Storage Account and Containers for Function Apps

---

## Files

```plaintext
Resource-Creation/
├── main.tf
├── providers.tf
├── variables.tf
├── outputs.tf
└── README.md
```

### `providers.tf`

Defines the Terraform Azure provider.

### `variables.tf`

Stores reusable variables such as:

- Existing resource group name
- VM administrator password

### `main.tf`

Creates the Azure resources.

### `outputs.tf`

Displays useful deployment outputs such as:

- Function App names
- VM public IP addresses

---

## Prerequisites

Install:

- Terraform
- Azure CLI

Login to Azure:

```bash
az login
```

Verify the active subscription:

```bash
az account show
```

Set the correct subscription if needed:

```bash
az account set --subscription "YOUR_SUBSCRIPTION_NAME_OR_ID"
```

---

## Deployment Steps

Navigate into this folder:

```bash
cd Resource-Creation
```

Initialize Terraform:

```bash
terraform init
```

Format the Terraform files:

```bash
terraform fmt
```

Validate the configuration:

```bash
terraform validate
```

Preview the resources that will be created:

```bash
terraform plan \
  -var="resource_group_name=YOUR_EXISTING_RESOURCE_GROUP" \
  -var="admin_password=YOUR_VM_PASSWORD"
```

Create the resources:

```bash
terraform apply \
  -var="resource_group_name=YOUR_EXISTING_RESOURCE_GROUP" \
  -var="admin_password=YOUR_VM_PASSWORD"
```

Type `yes` when prompted.

---

## Verify Deployment

List resources in the resource group:

```bash
az resource list \
  --resource-group YOUR_EXISTING_RESOURCE_GROUP \
  --output table
```

Check the virtual machines:

```bash
az vm list \
  --resource-group YOUR_EXISTING_RESOURCE_GROUP \
  --output table
```

Check Function Apps:

```bash
az functionapp list \
  --resource-group YOUR_EXISTING_RESOURCE_GROUP \
  --output table
```

Check Terraform state:

```bash
terraform state list
```

---

## Outputs

After deployment, Terraform displays:

```plaintext
vmstart_function_app_name
vmstop_function_app_name
vm1_public_ip
vm2_public_ip
```
<img width="1057" height="828" alt="Screenshot 2026-05-09 at 11 51 27 AM" src="https://github.com/user-attachments/assets/fcf3c156-e877-4e06-8471-17f75b03fc6b" />


Use the Function App names when deploying the Azure Function code from the `Start_VM` and `Stop_VM` folders.

---

## Cleanup

To remove the resources created by Terraform:

```bash
terraform destroy \
  -var="resource_group_name=YOUR_EXISTING_RESOURCE_GROUP" \
  -var="admin_password=YOUR_VM_PASSWORD"
```

Type `yes` when prompted.

---

## Troubleshooting

### Resource Provider Registration Error

If Terraform shows:

```plaintext
Terraform does not have the necessary permissions to register Resource Providers
```

Update the Azure provider block:

```hcl
provider "azurerm" {
  features {}

  resource_provider_registrations = "none"
}
```

Then run:

```bash
terraform init -upgrade
terraform plan
```

### VM Password Error

Azure requires a strong VM password.

Use a password that includes:

- Uppercase letters
- Lowercase letters
- Numbers
- Special characters

### Function App Name Already Exists

Azure Function App names must be globally unique.

If there is a name conflict, update the Function App name or use a random suffix.

---

## Notes

Do not commit sensitive values such as VM passwords to GitHub.

Use Terraform variables, environment variables, or a `.tfvars` file excluded by `.gitignore`.
