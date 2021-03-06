###################################################################################
#This module allows the creation of n Linux VM with 1 NIC
###################################################################################


output "Name" {
  value = azurerm_linux_virtual_machine.TerraVM.name
}

output "Id" {
  value = azurerm_linux_virtual_machine.TerraVM.id
}

output "NicId" {
  value = azurerm_network_interface.TerraVM-nic0.id
}

output "NicPrivateIp" {
  value = azurerm_network_interface.TerraVM-nic0.private_ip_address
}

output "RgName" {
  value = var.RgName
}
