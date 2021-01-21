############################################################
# This module allows the creation of n Linux VM with 1 NIC #
############################################################

# Create Password for vm
resource "random_password" "TerraVM-pass" {
  length = 16
  special = true
  override_special = "!@#$%"
}

# save password in keyvault secret
resource "azurerm_key_vault_secret" "TerraVM-secret" {
  name         = "${var.VmEnv}lin${format("%04d", var.VmNumber)}l-${var.VmAdminName}"
  value        = random_password.TerraVM-pass.result
  key_vault_id = var.KvId
  tags = {
    Environment       = var.EnvironmentTag
    EnvironmentUsage  = var.EnvironmentUsageTag
    Owner             = var.OwnerTag
    ProvisioningDate  = var.ProvisioningDateTag
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

# Create storage account for each VM Diag
resource azurerm_storage_account "TerraVM-diag" {
  name  =  "${var.VmEnv}lin${format("%04d", var.VmNumber)}ldiag"
  resource_group_name = var.RgName
  location = var.RgLocation
  account_tier = "Standard"
  account_replication_type = "LRS"
  tags = {
    Environment      = var.EnvironmentTag
    Usage            = var.EnvironmentUsageTag
    Owner            = var.OwnerTag
    ProvisioningDate = var.ProvisioningDateTag
    ProvisioningMode = var.ProvisioningModeTag
    #BackupRetention  = var.BackupRetention
  }
  lifecycle {
    ignore_changes = [
      tags["ProvisioningDate"],
    ]
  }
}

# Create 1 NIC pour each VM
resource "azurerm_network_interface" "TerraVM-nic0" {
  name                = "${var.VmEnv}lin${format("%04d", var.VmNumber)}l-nic0"
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
  name                = "${var.VmEnv}lin${format("%04d", var.VmNumber)}l"
  computer_name       = "${var.VmEnv}lin${format("%04d", var.VmNumber)}l"
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
    storage_account_uri  = azurerm_storage_account.TerraVM-diag.primary_blob_endpoint
  }

  #admin_ssh_key {
  #  username   = var.VmAdminName
  #  public_key = file("../../ssh_keys/ansible/ansible-covage.com-id_rsa.pub")
  #}

  os_disk {
    name                 = "${var.VmEnv}lin${format("%04d", var.VmNumber)}l-OsDisk"
    caching              = "ReadWrite"
    storage_account_type = var.VmStorageTier#"Standard_LRS"
  }

  source_image_reference {
    publisher = var.ImagePublisherName
    offer     = var.ImageOffer
    sku       = var.ImageSku
    version   = "latest"
  }

  zone = var.AvZone

  tags = {
    Environment       = var.EnvironmentTag
    Usage             = var.EnvironmentUsageTag
    Owner             = var.OwnerTag
    ProvisioningDate  = var.ProvisioningDateTag
    ProvisioningMode  = var.ProvisioningModeTag
    BackupRetention   = var.BackupRetention
  }

  lifecycle {
    ignore_changes = [
      tags["ProvisioningDate"],
    ]
  }
}
