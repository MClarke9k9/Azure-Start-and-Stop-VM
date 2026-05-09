# Azure Start and Stop Virtual Machines with Terraform + Azure Functions
<img width="1060" height="564" alt="AzureStartStop" src="https://github.com/user-attachments/assets/a8c7bfed-65d7-4d14-a675-a407c58c2eef" />

## Overview

This project automates the provisioning and management of Azure Virtual Machines using Terraform and Azure Functions.

The infrastructure deploys:

- Two Azure Function Apps using Flex Consumption Plan
- Two Azure Linux Virtual Machines
- Supporting Azure networking resources
- Storage Account for Function App deployment packages

The Azure Functions automatically:

- Start all virtual machines in a resource group
- Stop all virtual machines in a resource group

This solution is useful for:

- Cost optimization in development environments
- Automated VM lifecycle management

---

## Project Structure

```plaintext
Azure-Start-and-Stop-VM/
│
├── Resource-Creation/
│   ├── main.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── outputs.tf
│
├── Start_VM/
│   ├── function_app.py
│   ├── host.json
│   ├── requirements.txt
│
├── Stop_VM/
│   ├── function_app.py
│   ├── host.json
│   ├── requirements.txt
│
└── README.md
```

---

## Architecture

### Infrastructure Resources

Terraform creates:

### Function Apps

- VMStart Function App
- VMStop Function App

Configuration:

- Runtime: Python 3.10
- Hosting Plan: Flex Consumption
- Memory: 512MB
- Region: East US

### Virtual Machines

Terraform creates:

- myVM1
- myVM2

Configuration:

- Ubuntu Server 24.04 LTS
- Size: Standard_B1s
- Authentication: Password
- SSH Port: 22

### Networking

Terraform creates:

- Virtual Network
- Subnet
- Network Security Group
- Public IP Addresses
- Network Interfaces

### Storage

Terraform creates:

- Storage Account
- Storage Containers for Function Apps

---

## How It Works

### Start Function

Location:

```plaintext
Start_VM/function_app.py
```

Purpose:

Starts all VMs in the configured resource group.

Schedule:

Runs every 5 minutes.

Logic:

1. Authenticate using DefaultAzureCredential
2. Get all VMs in the resource group
3. Check power state
4. Start stopped VMs

---

### Stop Function

Location:

```plaintext
Stop_VM/function_app.py
```

Purpose:

Stops all running VMs in the configured resource group.

Schedule:

Runs every 5 minutes.

Logic:

1. Authenticate using DefaultAzureCredential
2. Get all VMs in the resource group
3. Check power state
4. Stop running VMs

---

## Requirements

### Software

Install:

### Terraform

[Terraform Official Site](https://developer.hashicorp.com/terraform/downloads?utm_source=chatgpt.com)

Verify:

```bash
terraform version
```

---

### Azure CLI

[Azure CLI Official Docs](https://learn.microsoft.com/cli/azure/install-azure-cli?utm_source=chatgpt.com)

Verify:

```bash
az version
```

---

### Azure Functions Core Tools

[Azure Functions Core Tools Docs](https://learn.microsoft.com/azure/azure-functions/functions-run-local?utm_source=chatgpt.com)

Verify:

```bash
func --version
```

---

### Python

Required version:

```plaintext
Python 3.10
```

Verify:

```bash
python3 --version
```

---

## Azure Authentication

Login:

```bash
az login
```

Set subscription:

```bash
az account set --subscription "YOUR_SUBSCRIPTION_NAME"
```

Verify:

```bash
az account show
```

---

## Deploy Azure Functions

### Deploy Start Function

Navigate:

```bash
cd Start_VM
```

Publish:

```bash
func azure functionapp publish FUNCTION_APP_NAME
```

---

### Deploy Stop Function

Navigate:

```bash
cd Stop_VM
```

Publish:

```bash
func azure functionapp publish FUNCTION_APP_NAME
```

---

## Environment Variables

Set these in both Function Apps:

```plaintext
AZURE_SUBSCRIPTION_ID
RESOURCE_GROUP
```

Set with CLI:

```bash
az functionapp config appsettings set \
--name FUNCTION_APP_NAME \
--resource-group RESOURCE_GROUP \
--settings AZURE_SUBSCRIPTION_ID=YOUR_SUBSCRIPTION_ID RESOURCE_GROUP=YOUR_RESOURCE_GROUP
```

---

## Required Permissions

Function Apps need:

Virtual Machine Contributor role

Assign role:

```bash
az role assignment create \
--assignee PRINCIPAL_ID \
--role "Virtual Machine Contributor" \
--scope /subscriptions/SUBSCRIPTION_ID/resourceGroups/RESOURCE_GROUP
```

---

## Troubleshooting

### Terraform Provider Registration Error

Fix:

```hcl
provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}
```

---

### Azure Function Publish Error

Error:

```plaintext
No Azure Function project root could be found
```

Fix:

Run inside project root:

```bash
cd Start_VM
```

or

```bash
cd Stop_VM
```

Make sure:

```plaintext
host.json
```

exists.

---

### Azure CLI Not Found

Install Azure CLI.

Verify:

```bash
az version
```

---

### Function Core Tools Not Found

Install Azure Functions Core Tools.

Verify:

```bash
func --version
```

---

## Cleanup

Destroy all infrastructure:

```bash
terraform destroy \
-var="resource_group_name=YOUR_RESOURCE_GROUP" \
-var="admin_password=YOUR_PASSWORD"
```

---

## Security Notes

Do not hardcode:

- Passwords
- Subscription IDs
- Secrets

Use:

- Terraform variables
- Azure Key Vault
- Managed Identity

---

## Future Improvements

Possible upgrades:

- Custom schedules for business hours
- Start specific VMs only
- Stop specific VMs only
- Email notifications
- Teams/Slack alerts
- Cost reporting

---

## Technologies Used

- Terraform
- Azure Functions
- Azure Virtual Machines
- Azure Storage
- Azure Networking
- Python
- Azure SDK for Python

---

## Author

Mark Clarke
