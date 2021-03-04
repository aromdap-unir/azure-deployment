### N E T W O R K  C R E A T I O N ###

# Virtual Network creation
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network
resource "azurerm_virtual_network" "VirtualNetwork" {
    name                = "kubernetesnet"
    address_space       = ["10.0.0.0/16"]
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    tags = {
        environment = "CP2"
    }
}
# Subnet creation
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet
resource "azurerm_subnet" "SubNet" {
    name                   = "terraformsubnet"
    resource_group_name    = azurerm_resource_group.rg.name
    virtual_network_name   = azurerm_virtual_network.VirtualNetwork.name
    address_prefixes       = ["10.0.1.0/24"]

}
# NIC creation
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface
resource "azurerm_network_interface" "NIC" {
  name                = "nic-${var.vms[count.index]}" 
  count               = length(var.vms) 
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

    ip_configuration {
    name                           = "ipconfig-${var.vms[count.index]}"
    subnet_id                      = azurerm_subnet.SubNet.id 
    private_ip_address_allocation  = "Static"
    private_ip_address             = "10.0.1.${count.index + 10}"
    public_ip_address_id           = azurerm_public_ip.PublicIp[count.index].id
  }

    tags = {
        environment = "CP2"
    }

}
# Public IP creation
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip
resource "azurerm_public_ip" "PublicIp" {
  name                = "pubip-${var.vms[count.index]}"
  count               = length(var.vms)
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static" #Dynamic
  sku                 = "Basic"

    tags = {
        environment = "CP2"
    }

}