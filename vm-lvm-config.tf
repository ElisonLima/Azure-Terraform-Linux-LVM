resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "East US"
}


resource "azurerm_virtual_network" "example" {
  name                = "example-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}


resource "azurerm_subnet" "example" {
  name                 = "example-subnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}


resource "azurerm_network_security_group" "example" {
  name                = "example-nsg"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "example" {
  name                = "example-public-ip"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Dynamic"  
  sku = "Basic"  
}


resource "azurerm_network_interface" "example" {
  name                = "example-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "example-ipconfig"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example.id 
  }
}


resource "azurerm_linux_virtual_machine" "example" {
  name                = "example-vm"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  size                = "Standard_B1ms"
  admin_username      = "azureuser"
  network_interface_ids = [azurerm_network_interface.example.id]

  admin_ssh_key { 
    username = "azureuser" 
    public_key = file(var.public_key) 
  }

  os_disk {
    caching      = "ReadWrite"
    disk_size_gb = 64
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

    custom_data = base64encode(<<-EOT
                runcmd:
                  - "sudo bash -c 'pvcreate /dev/sda'"
                  - "sudo vgcreate vg00 /dev/sda"
                  - "sudo lvcreate -n lv_root -L 5G vg00"
                  - "sudo mkfs.ext4 /dev/vg00/lv_root"
                  - "sudo mount /dev/vg00/lv_root /mnt"
                  - "sudo mkdir /mnt/boot"
                  - "sudo mkdir /mnt/var"
                  - "sudo mkdir /mnt/log"
                  - "sudo mkdir /mnt/home"
                  - "sudo mkdir /mnt/tmp"
                  - "sudo mount /dev/vg00/lv_root /mnt/boot"
                  - "sudo mount /dev/vg00/lv_root /mnt/var"
                  - "sudo mount /dev/vg00/lv_root /mnt/log"
                  - "sudo mount /dev/vg00/lv_root /mnt/home"
                  - "sudo mount /dev/vg00/lv_root /mnt/tmp"
                EOT
                )

}