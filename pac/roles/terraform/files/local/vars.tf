variable droplets {
    type        = list(
        object({
            ip              = string
            hostname        = string
            disks           = list(
                object({
                    path    = string
                    name    = string
                    size    = number
                })
            )
            spec            = object({
                cpus    = number
                memory  = number
            })
        })
    )
    description = "Droplet servers to create.  If droplet does not need external drives, then make disk.count = 0"
    nullable = false

    validation {
        condition = alltrue([
            for droplet in var.droplets : droplet.spec.cpus > 0 && droplet.spec.memory > 0
        ])
        error_message = "Cpus and memory must be postive numbers"
    }
}

variable storage_pool {
    type    = object({
        name    = string
        source  = string
        size    = number
        driver  = string
    })
    description = "Storage pool settings to store an external drives"
    default = {
        name    = "pac"
        source  = "/var/snap/lxd/common/lxd/disks/pac.img"
        size    = 20
        driver  = "zfs"
    }

     validation {
        condition       = var.storage_pool.size > 0
        error_message   = "Pool size must be positive number"
    }

     validation {
        condition       = contains(["dir", "lvm", "btrfs", "zfs"], var.storage_pool.driver)
        error_message   = "Invalid driver type"
    }
}

variable pac_network {
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