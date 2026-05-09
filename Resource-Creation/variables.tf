variable "resource_group_name" {
  description = "Existing Azure Resource Group name."
  type        = string
}

variable "admin_password" {
  description = "Password for VM admin account."
  type        = string
  sensitive   = true
}