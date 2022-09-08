locals {
    droplet_disks = flatten([
        for droplet in var.droplets : [
            for i, disk in droplet.disks : {
                ip = droplet.ip
                hostname = droplet.hostname
                disk_path = disk.path
                disk_name = disk.name
                disk_size = disk.size
            }
        ]
    ])
}
