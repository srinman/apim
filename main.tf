terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}
provider "azurerm" {
    features {}
    subscription_id = "bc288fdd-c41e-4334-961a-26e993d3c506"
    use_msi = true
}

resource "azurerm_virtual_network" "vnet_apim" {
    name                        = "vnet-apim"
    location                    = "centralus"
    resource_group_name         = "apimrg"
    address_space               = ["10.0.0.0/16"]
}


resource "azurerm_subnet" "apimsubnet" {
    name                        = "apimsubnet"
    resource_group_name         = "apimrg"
    virtual_network_name        = "vnet-apim"
    address_prefixes            = ["10.0.0.0/24"]
}

resource "azurerm_network_security_group" "apim_nsg" {
    name                = "apim-nsg"
    location                    = "centralus"
    resource_group_name         = "apimrg"
}

resource "azurerm_subnet_network_security_group_association" "apim_subnet_assign_nsg" {
  subnet_id                 = azurerm_subnet.apimsubnet.id
  network_security_group_id = azurerm_network_security_group.apim_nsg.id
}

resource "azurerm_route_table" "apim_route_table" {
    name                          = "apim-route-table"
    location                    = "centralus"
    resource_group_name         = "apimrg"
    disable_bgp_route_propagation = false
}

resource "azurerm_route" "internet_egress" {
    name                    = "Internet-Outbound"
    resource_group_name         = "apimrg"
    route_table_name        = azurerm_route_table.apim_route_table.name
    address_prefix          = "0.0.0.0/0"
    next_hop_type           = "VirtualAppliance"
    next_hop_in_ip_address  = azurerm_firewall.azure_firewall_instance.ip_configuration[0].private_ip_address
    depends_on = [ azurerm_firewall.azure_firewall_instance ]
}

resource "azurerm_subnet_route_table_association" "apim_route_table_assoc" {
    subnet_id       = azurerm_subnet.apimsubnet.id
    route_table_id  = azurerm_route_table.apim_route_table.id
}


resource "azurerm_virtual_network" "vnet_fw" {
    name                        = "vnet-fw"
    location                    = "centralus"
    resource_group_name         = "apimrg"
    address_space               = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "firewall_subnet" {
    name                        = "AzureFirewallSubnet"
    resource_group_name         = "apimrg"
    virtual_network_name        = "vnet-fw"
    address_prefixes            = ["10.1.0.0/24"]
       depends_on = [
                   azurerm_virtual_network.vnet_fw
                 ]
}

resource "azurerm_network_security_group" "fw-nsg" {
    name                = "fw-nsg"
    location                    = "centralus"
    resource_group_name         = "apimrg"
}






resource "azurerm_public_ip" "azure_firewall_pip" {
    name                        = "azure_firewall_pip"
    location                    = "centralus"
    resource_group_name         = "apimrg"
    allocation_method           = "Static"
    sku                         = "Standard"
}


resource "azurerm_firewall" "azure_firewall_instance" {
    name                        = "azure-firewall"
    sku_tier                    = "Standard"
    sku_name                    = "AZFW_VNet"
    location                    = "centralus"
    resource_group_name         = "apimrg"
    ip_configuration {
        name                    = "configuration"
        subnet_id               = azurerm_subnet.firewall_subnet.id
        public_ip_address_id    = azurerm_public_ip.azure_firewall_pip.id
    }
}

resource "azurerm_firewall_network_rule_collection" "apim_network_rules" {
    name                = "apim-network-rules"
    azure_firewall_name = azurerm_firewall.azure_firewall_instance.name
    resource_group_name         = "apimrg"
    priority            = 100
    action              = "Allow"
    rule {
        name = "Storage"
        source_addresses = [
            "*"
        ]
        destination_addresses = [
            "Storage"
        ]
        destination_ports = [
            "443"
        ]
        protocols = [
            "TCP"
        ]
    }
    rule {
        name = "SQL"
        source_addresses = [
            "*"
        ]
        destination_addresses = [
            "SQL"
        ]
        destination_ports = [
            "1443"
        ]
        protocols = [
            "TCP"
        ]
    }
    rule {
        name = "KeyVault"
        source_addresses = [
            "*"
        ]
        destination_addresses = [
            "AzureKeyVault"
        ]
        destination_ports = [
            "443"
        ]
        protocols = [
            "TCP"
        ]
    }
}

resource "azurerm_virtual_network_peering" "fw_apim_peering" {
    name                        = "fw-apim-peering"
    resource_group_name         = "apimrg"
    virtual_network_name        = azurerm_virtual_network.vnet_fw.name
    remote_virtual_network_id   = azurerm_virtual_network.vnet_apim.id
}

resource "azurerm_virtual_network_peering" "apim_fw_peering" {
    name                        = "apim_fw_peer"
    resource_group_name         = var.resource_group_name
    virtual_network_name        = azurerm_virtual_network.vnet_apim.name
    remote_virtual_network_id   = azurerm_virtual_network.vnet_fw.id
}
