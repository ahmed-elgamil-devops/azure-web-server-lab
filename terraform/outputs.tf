output "web_url" {
  description = "Open this in a browser to see the Nginx page."
  value       = "http://${azurerm_public_ip.web.ip_address}"
}

output "ssh_command" {
  description = "Ready-made SSH command for the VM."
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.web.ip_address}"
}

output "backup_storage_account" {
  description = "Storage account holding the backup container."
  value       = azurerm_storage_account.backups.name
}

output "resource_group" {
  description = "Delete this resource group to remove every resource in the lab."
  value       = azurerm_resource_group.main.name
}
