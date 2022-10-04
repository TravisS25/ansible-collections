provider "lxd" {}

resource "lxd_network" "network" {
    name = "${var.network.name}"
    
    config = {
        "ipv4.address" = var.network.ipv4_cidr
        "ipv4.nat"     = true
    }
}

resource "lxd_storage_pool" "pac_pool" {
    name = "${var.storage_pool.name}"
    driver = "${var.storage_pool.driver}"
    config = {
        source                      = "${var.storage_pool.source}"
        size                        = "${tostring(var.storage_pool.size)}GiB"
        "volume.block.filesystem"   = "${var.storage_pool.fstype}"
    }
}

resource "lxd_volume" "pac_volumes" {
    depends_on = [lxd_storage_pool.pac_pool]

    for_each = {
        for disk in local.droplet_disks : "${disk.hostname}__${disk.disk_name}" => disk
    }

    name = "${each.key}"
    pool = "${lxd_storage_pool.pac_pool.name}"
    config = {
        size = "${each.value.disk_size}GiB"
    }
}

resource "lxd_container" "droplets" {
    depends_on = [lxd_volume.pac_volumes, lxd_network.network]

    count = length(local.droplets)

    name      = "${local.droplets[count.index].hostname}"
    image     = "ubuntu:e299296138c2"
    ephemeral = false
    start_container = true

    config = {
        "boot.autostart"        = true
        "user.user-data"        = <<-EOT
            #cloud-config

            ${yamlencode(local.droplets[count.index].cloud_init.user_data)}
        EOT
        "user.network-config"   = yamlencode(local.droplets[count.index].cloud_init.network_config)
    }

    limits = {
        cpu     = "${tostring(local.droplets[count.index].specs.cpus)}"
        memory  = "${tostring(local.droplets[count.index].specs.memory)}MiB"
    }

    device {
        name = "eth0"
        type = "nic"

        properties = {
            nictype         = "bridged"
            parent          = "${lxd_network.network.name}"
            "ipv4.address"  = "${local.droplets[count.index].ip}"
        }
    }

    device {
        type = "disk"
        name = "root"

        properties = {
            path = "/"
            pool = "${lxd_storage_pool.pac_pool.name}"
        }
    }

    dynamic "device" {
        for_each = { 
            for item in lookup(local.droplets[count.index].specs, "disks", []): item.name => item
        }

        content {
            name =  "${device.value.name}"
            type = "disk"
            properties = {
                path    = "${device.value.path}"
                source  = "${local.droplets[count.index].hostname}__${device.value.name}"
                pool    = "${lxd_storage_pool.pac_pool.name}"
            }
        }
    }
}