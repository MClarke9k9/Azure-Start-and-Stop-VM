data "azurerm_resource_group" "existing" {
  name = var.resource_group_name
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

locals {
  location = "East US"
  tags = {
    environment = "lab"
    project     = "vm-start-stop"
  }
}

# Storage for Function Apps
resource "azurerm_storage_account" "functions" {
  name                     = "funcstor${random_string.suffix.result}"
  resource_group_name      = data.azurerm_resource_group.existing.name
  location                 = local.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.tags
}

resource "azurerm_storage_container" "vmstart" {
  name                  = "vmstart"
  storage_account_id    = azurerm_storage_account.functions.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "vmstop" {
  name                  = "vmstop"
  storage_account_id    = azurerm_storage_account.functions.id
  container_access_type = "private"
}

# Flex Consumption Plan
resource "azurerm_service_plan" "flex" {
  name                = "asp-flex-vmstartstop"
  resource_group_name = data.azurerm_resource_group.existing.name
  location            = local.location
  os_type             = "Linux"
  sku_name            = "FC1"
  tags                = local.tags
}

# Function App: VMStart
resource "azurerm_function_app_flex_consumption" "vmstart" {
  name                = "vmstart-${random_string.suffix.result}"
  resource_group_name = data.azurerm_resource_group.existing.name
  location            = local.location
  service_plan_id     = azurerm_service_plan.flex.id

  storage_container_type      = "blobContainer"
  storage_container_endpoint  = "${azurerm_storage_account.functions.primary_blob_endpoint}${azurerm_storage_container.vmstart.name}"
  storage_authentication_type = "StorageAccountConnectionString"
  storage_access_key          = azurerm_storage_account.functions.primary_access_key

  runtime_name           = "python"
  runtime_version        = "3.10"
  instance_memory_in_mb  = 512
  maximum_instance_count = 50

  site_config {}

  tags = local.tags
}

# Function App: VMStop
resource "azurerm_function_app_flex_consumption" "vmstop" {
  name                = "vmstop-${random_string.suffix.result}"
  resource_group_name = data.azurerm_resource_group.existing.name
  location            = local.location
  service_plan_id     = azurerm_service_plan.flex.id

  storage_container_type      = "blobContainer"
  storage_container_endpoint  = "${azurerm_storage_account.functions.primary_blob_endpoint}${azurerm_storage_container.vmstop.name}"
  storage_authentication_type = "StorageAccountConnectionString"
  storage_access_key          = azurerm_storage_account.functions.primary_access_key

  runtime_name           = "python"
  runtime_version        = "3.10"
  instance_memory_in_mb  = 512
  maximum_instance_count = 50

  site_config {}

  tags = local.tags
}

# Networking
resource "azurerm_virtual_network" "main" {
  name                = "vnet-vm-lab"
  address_space       = ["10.0.0.0/16"]
  location            = local.location
  resource_group_name = data.azurerm_resource_group.existing.name
  tags                = local.tags
}

resource "azurerm_subnet" "main" {
  name                 = "subnet-vm-lab"
  resource_group_name  = data.azurerm_resource_group.existing.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "ssh" {
  name                = "nsg-allow-ssh"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.existing.name
  tags                = local.tags

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "vm1" {
  name                = "pip-myVM1"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.existing.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_public_ip" "vm2" {
  name                = "pip-myVM2"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.existing.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_network_interface" "vm1" {
  name                = "nic-myVM1"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.existing.name
  tags                = local.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm1.id
  }
}

resource "azurerm_network_interface" "vm2" {
  name                = "nic-myVM2"
  location            = local.location
  resource_group_name = data.azurerm_resource_group.existing.name
  tags                = local.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm2.id
  }
}

resource "azurerm_network_interface_security_group_association" "vm1" {
  network_interface_id      = azurerm_network_interface.vm1.id
  network_security_group_id = azurerm_network_security_group.ssh.id
}

resource "azurerm_network_interface_security_group_association" "vm2" {
  network_interface_id      = azurerm_network_interface.vm2.id
  network_security_group_id = azurerm_network_security_group.ssh.id
}

# VM1
resource "azurerm_linux_virtual_machine" "vm1" {
  name                            = "myVM1"
  resource_group_name             = data.azurerm_resource_group.existing.name
  location                        = local.location
  size                            = "Standard_B1s"
  admin_username                  = "AdminUser"
  admin_password                  = var.admin_password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.vm1.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  tags = local.tags
}

# VM2
resource "azurerm_linux_virtual_machine" "vm2" {
  name                            = "myVM2"
  resource_group_name             = data.azurerm_resource_group.existing.name
  location                        = local.location
  size                            = "Standard_B1s"
  admin_username                  = "AdminUser"
  admin_password                  = var.admin_password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.vm2.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  tags = local.tags
}