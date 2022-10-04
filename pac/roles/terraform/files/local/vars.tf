variable dns_server_ip {
    type        = string
    default     = "192.168.3.2"
    description = "Static ip for dns server"
}

variable pac_server1_ip {
    type        = string
    default     = "192.168.3.3"
    description = "Static ip for pac server 1 server"
}

variable pac_server2_ip {
    type        = string
    default     = "192.168.3.4"
    description = "Static ip for pac server 2 server"
}

variable pac_server3_ip {
    type        = string
    default     = "192.168.3.5"
    description = "Static ip for pac server 3 server"
}

variable pac_server4_ip {
    type        = string
    default     = "192.168.3.6"
    description = "Static ip for pac server 4 server"
}

variable storage_pool {
    type    = object({
        name    = string
        source  = string
        size    = number
        driver  = string
        fstype  = string
    })
    description = "Storage pool settings to store an external drives"
    default = {
        name    = "pac"
        source  = "/var/snap/lxd/common/lxd/disks/pac.img"
        size    = 20
        driver  = "lvm"
        fstype  = "xfs"
    }

    validation {
        condition       = var.storage_pool.size > 0
        error_message   = "Pool size must be positive number"
    }

    validation {
        condition       = contains(["btrfs", "ext4", "xfs"], var.storage_pool.fstype)
        error_message   = "Pool fstype must be btrfs, ext4, xfs"
    }
}

variable network {
    type = object({
        name         = string
        ipv4_cidr    = string
    })
    default = {
        name        = "pac_dev"
        ipv4_cidr   = "192.168.3.1/24"
    }
    description = "Network for pac dev environment"
}