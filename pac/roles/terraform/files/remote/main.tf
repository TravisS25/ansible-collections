terraform {
    backend "local" {}
    required_providers {
        lxd = {
            source = "terraform-lxd/lxd"
            version = ">= 1.7.2"
        }
    }
}

provider "lxd" {}

resource "lxd_network" "network" {
    name = "pac_dev"
    
    config = {
        "ipv4.address" = "192.168.3.1/24"
        "ipv4.nat"     = true
    }
}

