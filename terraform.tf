variable "default_user" {}
variable "default_password" {}
variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}

provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
}


resource "azurerm_resource_group" "test" {
    name = "RemoveTerraform"
    location = "Japan East"
}

resource "azurerm_virtual_network" "test" {
    name = "acctvn"
    address_space = ["10.0.0.0/16"]
    location = "Japan East"
    resource_group_name = "${azurerm_resource_group.test.name}"
}

resource "azurerm_subnet" "test" {
    name = "acctsub"
    resource_group_name = "${azurerm_resource_group.test.name}"
    virtual_network_name = "${azurerm_virtual_network.test.name}"
    address_prefix = "10.0.2.0/24"
}

resource "azurerm_public_ip" "test" {
    name = "TerraformIP"
    location = "Japan East"
    resource_group_name = "${azurerm_resource_group.test.name}"
    public_ip_address_allocation = "static"
    domain_name_label = "terralinux"
    tags {
        environment = "Production"
    }
}

resource "azurerm_network_interface" "test" {
    name = "acctni"
    location = "Japan East"
    resource_group_name = "${azurerm_resource_group.test.name}"

    ip_configuration {
        name = "testconfiguration1"
        subnet_id = "${azurerm_subnet.test.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id = "${azurerm_public_ip.test.id}"
    }
}



resource "azurerm_storage_account" "test" {
    name = "accsa1971ec"
    resource_group_name = "${azurerm_resource_group.test.name}"
    location = "japaneast"
    account_type = "Standard_LRS"

    tags {
        environment = "staging"
    }
}

resource "azurerm_storage_container" "test" {
    name = "vhds"
    resource_group_name = "${azurerm_resource_group.test.name}"
    storage_account_name = "${azurerm_storage_account.test.name}"
    container_access_type = "private"
}

resource "azurerm_virtual_machine" "test" {
    name = "TerraformVM02"
    location = "Japan East"
    resource_group_name = "${azurerm_resource_group.test.name}"
    network_interface_ids = ["${azurerm_network_interface.test.id}"]
    vm_size = "Standard_A0"

    storage_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "14.04.2-LTS"
    version = "latest"
    }

    storage_os_disk {
        name = "myosdisk1"
        vhd_uri = "${azurerm_storage_account.test.primary_blob_endpoint}${azurerm_storage_container.test.name}/myosdisk1.vhd"
        caching = "ReadWrite"
        create_option = "FromImage"
    }

    os_profile {
    computer_name = "TerraformTest"
    admin_username = "${var.default_user}"
    admin_password = "${var.default_password}"
    }

    os_profile_linux_config {
    disable_password_authentication = false
    }
    
}