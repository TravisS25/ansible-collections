locals {
    droplet_disks = flatten([
        for droplet in var.droplets : [
            for disk in droplet.specs.disks : {
                hostname    = droplet.hostname
                disk_path   = disk.path
                disk_name   = disk.name
                disk_size   = disk.size
            }
        ]
    ])
}
