variable droplets {
    type        = list(
        object({
            ip              = string
            hostname        = string
            cloud_init      = object({
                network_config_file  = string
                user_data_file       = string
            })
            specs            = object({
                cpus    = number
                memory  = number
                disks           = list(
                    object({
                        path    = string
                        name    = string
                        size    = number
                    })
                )
            })
        })
    )
    description = "Droplet servers to create.  If droplet does not need external drives, then make disk.count = 0"
    nullable = false

    validation {
        condition = alltrue([
            for droplet in var.droplets : droplet.specs.cpus > 0 && droplet.specs.memory > 0
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