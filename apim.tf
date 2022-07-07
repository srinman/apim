resource "azurerm_api_management" "example" {
  name                = "example-apim"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  publisher_name      = "My Company"
  publisher_email     = "company@terraform.io"
  sku_name = "Premium"
  public_network_access_enabled = false
  virtual_network_type = "Internal"

  virtual_network_configuration {
    subnet_id =  data.azurerm_subnet.example.id
  }
}
