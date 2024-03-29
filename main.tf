############################################################
# This module allows the creation of n Linux VM with 1 NIC #
############################################################

locals {
  vm_name_prefix = "${var.VmEnv}lin${format("%04d", var.VmNumber)}"
  ProvisioningDateTag = timestamp()
}

# Create Password for vm
resource "random_password" "TerraVM-pass" {
  length = 16
  special = true
  min_lower = 1
  min_numeric = 1
  min_special = 1
  min_upper = 1
  override_special = "!@#$%"
}

# save password in keyvault secret
resource "azurerm_key_vault_secret" "TerraVM-secret" {
  name         = "${local.vm_name_prefix}-${var.VmAdminName}"
  value        = random_password.TerraVM-pass.result
  key_vault_id = var.KvId
  tags = {
    Environment       = var.EnvironmentTag
    Usage             = var.UsageTag
    Owner             = var.OwnerTag
    ProvisioningDate  = local.ProvisioningDateTag
    ProvisioningMode  = var.ProvisioningModeTag
    Username          = var.VmAdminName
  }
  lifecycle {
    ignore_changes = [
      value,
      tags["ProvisioningDate"],
    ]
  }
}

data "azurerm_storage_account" "TerraVM-diag" {
  name = var.VmDiag
  resource_group_name = var.RgVmDiag
}

# Create 1 NIC pour each VM
resource "azurerm_network_interface" "TerraVM-nic0" {
  name                = "${local.vm_name_prefix}-nic0"
  resource_group_name = var.RgName
  location            = var.RgLocation
  #dns_servers         = var.Dns

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.SubnetId
    private_ip_address_allocation = "Dynamic"
  }
}

# Create n VM
resource "azurerm_linux_virtual_machine" "TerraVM" {
  name                = local.vm_name_prefix
  computer_name       = local.vm_name_prefix
  resource_group_name = var.RgName
  location            = var.RgLocation
  size                = var.VmSize
  admin_username      = var.VmAdminName
  admin_password      = random_password.TerraVM-pass.result #var.VmAdminPassword
  disable_password_authentication = "false"
 
  network_interface_ids = [
    azurerm_network_interface.TerraVM-nic0.id,
  ]
  boot_diagnostics {
    storage_account_uri  = data.azurerm_storage_account.TerraVM-diag.primary_blob_endpoint
  }

  os_disk {
    name                 = "${local.vm_name_prefix}-OsDisk"
    caching              = "ReadWrite"
    storage_account_type = var.VmStorageTier#"Standard_LRS"
    disk_size_gb         = var.OsDiskSize
  }

  source_image_reference {
    publisher = var.ImagePublisherName
    offer     = var.ImageOffer
    sku       = var.ImageSku
    version   = var.ImageVersion#"latest"
  }

  zone = var.AvZone

  tags = {
    Environment       = var.EnvironmentTag
    Usage             = var.UsageTag
    Owner             = var.OwnerTag
    ProvisioningDate  = local.ProvisioningDateTag
    ProvisioningMode  = var.ProvisioningModeTag
    BackupRetention   = var.BackupRetention
  }

  lifecycle {
    ignore_changes = [
      tags["ProvisioningDate"],
      #admin_password,
    ]
  }
}

resource "azurerm_virtual_machine_extension" "azuread-auth" {
  name                 = "AADloginForLinux"
  virtual_machine_id   = azurerm_linux_virtual_machine.TerraVM.id
  publisher            = "Microsoft.Azure.ActiveDirectory.LinuxSSH"
  type                 = "AADLoginForLinux"
  type_handler_version = "1.0"
}