output "vmstart_function_app_name" {
  value = azurerm_function_app_flex_consumption.vmstart.name
}

output "vmstop_function_app_name" {
  value = azurerm_function_app_flex_consumption.vmstop.name
}

output "vm1_public_ip" {
  value = azurerm_public_ip.vm1.ip_address
}

output "vm2_public_ip" {
  value = azurerm_public_ip.vm2.ip_address
}