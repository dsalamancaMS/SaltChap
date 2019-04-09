resource "azurerm_resource_group" "salt" {
 name     = "Salt"
 location = "East US"
}

resource "azurerm_virtual_network" "salt" {
 name                = "saltnet"
 address_space       = ["10.0.0.0/16"]
 location            = "${azurerm_resource_group.salt.location}"
 resource_group_name = "${azurerm_resource_group.salt.name}"
}

resource "azurerm_subnet" "salt" {
 name                 = "saltsubnet"
 resource_group_name  = "${azurerm_resource_group.salt.name}"
 virtual_network_name = "${azurerm_virtual_network.salt.name}"
 address_prefix       = "10.0.0.0/24"
}

resource "azurerm_network_security_group" "saltlb" {
  name                = "lb-nsg"
  location            = "${azurerm_resource_group.salt.location}"
  resource_group_name = "${azurerm_resource_group.salt.name}"
}

resource "azurerm_network_security_rule" "httpslb" {
  name                        = "https"
  priority                    = 100
  direction                   = "inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "8443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.salt.name}"
  network_security_group_name = "${azurerm_network_security_group.saltlb.name}"
}

resource "azurerm_network_security_rule" "httplb" {
  name                        = "http"
  priority                    = 101
  direction                   = "inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "8080"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.salt.name}"
  network_security_group_name = "${azurerm_network_security_group.saltlb.name}"
}

resource "azurerm_network_security_rule" "sshlb" {
  name                        = "sshlb"
  priority                    = 103
  direction                   = "inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.salt.name}"
  network_security_group_name = "${azurerm_network_security_group.saltlb.name}"
}

resource "azurerm_network_security_group" "saltMaster" {
  name                = "masternsg"
  location            = "${azurerm_resource_group.salt.location}"
  resource_group_name = "${azurerm_resource_group.salt.name}"
}

resource "azurerm_network_security_rule" "publisher" {
  name                        = "publisher"
  priority                    = 100
  direction                   = "inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "4505"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.salt.name}"
  network_security_group_name = "${azurerm_network_security_group.saltMaster.name}"
}

resource "azurerm_network_security_rule" "requestsrv" {
  name                        = "requestsrv"
  priority                    = 101
  direction                   = "inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "4506"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.salt.name}"
  network_security_group_name = "${azurerm_network_security_group.saltMaster.name}"
}

resource "azurerm_network_security_rule" "sshmaster" {
  name                        = "ssh"
  priority                    = 103
  direction                   = "inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${azurerm_resource_group.salt.name}"
  network_security_group_name = "${azurerm_network_security_group.saltMaster.name}"
}

resource "azurerm_network_security_group" "saltMinions" {
  name                = "saltminions"
  location            = "${azurerm_resource_group.salt.location}"
  resource_group_name = "${azurerm_resource_group.salt.name}"
}

resource "azurerm_public_ip" "saltnginxpip" {
 name                         = "lbpip"
 location                     = "${azurerm_resource_group.salt.location}"
 resource_group_name          = "${azurerm_resource_group.salt.name}"
 public_ip_address_allocation = "static"
}

resource "azurerm_network_interface" "saltlb" {
 name                = "lbnic"
 location            = "${azurerm_resource_group.salt.location}"
 resource_group_name = "${azurerm_resource_group.salt.name}"
 network_security_group_id  = "${azurerm_network_security_group.saltlb.id}"

 ip_configuration {
   name                          = "lbip"
   subnet_id                     = "${azurerm_subnet.salt.id}"
   private_ip_address_allocation = "dynamic"
   public_ip_address_id          = "${azurerm_public_ip.saltnginxpip.id}"
 }
}

resource "azurerm_network_interface" "saltminions" {
 count               = 2
 name                = "webnic${count.index}"
 location            = "${azurerm_resource_group.salt.location}"
 resource_group_name = "${azurerm_resource_group.salt.name}"
 network_security_group_id  = "${azurerm_network_security_group.saltMinions.id}"

 ip_configuration {
   name                          = "web${count.index}"
   subnet_id                     = "${azurerm_subnet.salt.id}"
   private_ip_address_allocation = "dynamic"
 }
}

resource "azurerm_public_ip" "saltmasterpip" {
  name                    = "masterpip"
  location                = "${azurerm_resource_group.salt.location}"
  resource_group_name     = "${azurerm_resource_group.salt.name}"
  allocation_method       = "Dynamic"
}

resource "azurerm_network_interface" "saltmaster" {
 name                = "masternic"
 location            = "${azurerm_resource_group.salt.location}"
 resource_group_name = "${azurerm_resource_group.salt.name}"
 network_security_group_id     = "${azurerm_network_security_group.saltMaster.id}"

 ip_configuration {
   name                          = "masterip"
   subnet_id                     = "${azurerm_subnet.salt.id}"
   private_ip_address_allocation = "static"
   private_ip_address            = "10.0.0.10"
   public_ip_address_id          = "${azurerm_public_ip.saltmasterpip.id}"
 }
}


resource "azurerm_virtual_machine" "saltminions" {
 count                 = 2
 name                  = "web-0${count.index}"
 location              = "${azurerm_resource_group.salt.location}"
 resource_group_name   = "${azurerm_resource_group.salt.name}"
 network_interface_ids = ["${element(azurerm_network_interface.saltminions.*.id, count.index)}"]
 vm_size               = "Standard_B1s"

 storage_image_reference {
   publisher = "Canonical"
   offer     = "UbuntuServer"
   sku       = "16.04-LTS"
   version   = "latest"
 }

 storage_os_disk {
   name              = "webosdisk${count.index}"
   caching           = "ReadWrite"
   create_option     = "FromImage"
   managed_disk_type = "Standard_LRS"
 }

 os_profile {
   computer_name  = "web-0${count.index}"
   admin_username = "dsala"
 }

 os_profile_linux_config {
   disable_password_authentication = true
     ssh_keys = {
      path     = "/home/dsala/.ssh/authorized_keys"
      key_data = "${file("~/.ssh/id_rsa.pub")}"
    }
 }
}

resource "azurerm_virtual_machine" "saltmaster" {
 name                  = "salt"
 location              = "${azurerm_resource_group.salt.location}"
 resource_group_name   = "${azurerm_resource_group.salt.name}"
 network_interface_ids = ["${azurerm_network_interface.saltmaster.id}"]
 vm_size               = "Standard_B1ms"

 storage_image_reference {
   publisher = "OpenLogic"
   offer     = "CentOS"
   sku       = "7.5"
   version   = "latest"
 }

 storage_os_disk {
   name              = "saltos"
   caching           = "ReadWrite"
   create_option     = "FromImage"
   managed_disk_type = "Standard_LRS"
 }

 os_profile {
   computer_name  = "salt"
   admin_username = "dsala"
 }

 os_profile_linux_config {
   disable_password_authentication = true
     ssh_keys = {
      path     = "/home/dsala/.ssh/authorized_keys"
      key_data = "${file("~/.ssh/id_rsa.pub")}"
    }
 }
}

resource "azurerm_virtual_machine" "saltlb" {
 name                  = "lb-vm"
 location              = "${azurerm_resource_group.salt.location}"
 resource_group_name   = "${azurerm_resource_group.salt.name}"
 network_interface_ids = ["${azurerm_network_interface.saltlb.id}"]
 vm_size               = "Standard_B1ms"

 storage_image_reference {
   publisher = "OpenLogic"
   offer     = "CentOS"
   sku       = "7.5"
   version   = "latest"
 }

 storage_os_disk {
   name              = "lbos"
   caching           = "ReadWrite"
   create_option     = "FromImage"
   managed_disk_type = "Standard_LRS"
 }

 os_profile {
   computer_name  = "lb-vm"
   admin_username = "dsala"
 }

 os_profile_linux_config {
   disable_password_authentication = true
     ssh_keys = {
      path     = "/home/dsala/.ssh/authorized_keys"
      key_data = "${file("~/.ssh/id_rsa.pub")}"
    }
 }
}