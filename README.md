# Linux Server Module
This module allows you to create 1 Linux Server VM with 1 NIC
It will:
  - create 1 Linux VM (hostname and VM named according to naming system)
  - create 1 NIC 
  - generate random admin password for VM admin (default admin name is admlocal)
  - create 1 secret in provided keyvault to store the admin password (the secret name will be hostname-admin_name, depending on variable VmAdminName value: !!!underscore unauthorized!!!)
  - create various tags (you should add your iwn default tags)

# Required resources
- existing Resource Group
- existing Keyvault
- existing Subnet
- existing VNet

## Usage Example :

```hcl
module "testVM" {
  source = "github.com/nfrappart/azTerraVmLinuxAvZone"
  RgName = module.rg-core-eu.Name #call existing RG name
  RgLocation = module.rg-core-eu.Location #call existing RG location
  VmEnv = "test"
  VmNumber = "100" # /!\ Important - list the server IDs to provision. This parameter is used for naming convention
  VmSize = "Standard_B1ms" #(choose the right size for the need)
  #AvZone = "1" #(optional, Availability Zone default value is "1")
  #VmStorageTier = "Standard_LRS" #optional, default is Premium_LRS if not provided
  KvId = module.Kv-DemoVault.Id #specify the Keyvault resource id where the secret must be created
  ImagePublisherName = "Canonical"
  ImageOffer = "UbuntuServer"
  ImageSku = "18.04-LTS"
  SubnetId = module.sn-test-hub-eu.Id #call existing subnet id
  ProvisioningDateTag = timestamp() #required!
  EnvironmentTag = "testing"
}
```
