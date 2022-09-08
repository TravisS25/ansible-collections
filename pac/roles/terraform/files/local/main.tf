provider "lxd" {}

resource "lxd_cached_image" "focal" {
    source_remote = "ubuntu"
    source_image  = "e299296138c2"
    aliases = ["ubuntu_20.04"]
}

resource "lxd_network" "pac_network" {
    name = "${var.pac_network.name}"

    config = {
        "ipv4.address" = var.pac_network.ipv4_cidr
        "ipv4.nat"     = true
    }
}

resource "lxd_storage_pool" "pac_pool" {
    name = "${var.storage_pool.name}"
    driver = "${var.storage_pool.driver}"
    config = {
        source          = "${var.storage_pool.source}"
        size            = "${tostring(var.storage_pool.size)}GiB"
        "zfs.pool_name" = "${var.storage_pool.name}"
    }
}

resource "lxd_volume" "pac_volumes" {
    depends_on = [lxd_storage_pool.pac_pool]

    count = length(local.droplet_disks)

    name = "${local.droplet_disks[count.index].hostname}.${local.droplet_disks[count.index].disk_name}"
    pool = "${lxd_storage_pool.pac_pool.name}"
    config = {
        size = "${tostring(local.droplet_disks[count.index].disk_size)}GiB"
    }
}

resource "lxd_container" "droplets" {
    depends_on = [lxd_volume.pac_volumes, lxd_network.pac_network, lxd_cached_image.focal]

    count = length(var.droplets)

    name      = "${var.droplets[count.index].hostname}"
    image     = "${lxd_cached_image.focal.fingerprint}"
    ephemeral = false
    start_container = true

    config = {
        "boot.autostart" = true
    }

    limits = {
        cpu     = "${tostring(var.droplets[count.index].spec.cpus)}"
        memory  = "${tostring(var.droplets[count.index].spec.memory)}MiB"
    }

    device {
        name = "eth0"
        type = "nic"

        properties = {
            nictype         = "bridged"
            parent          = "${lxd_network.pac_network.name}"
            "ipv4.address"  = "${var.droplets[count.index].ip}"
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
            for item in var.droplets[count.index].disks: item.name => item if item.size > 0 
        }

        content {
            name =  "${device.value.name}"
            type = "disk"
            properties = {
                path    = "${device.value.path}${device.value.name}"
                source  = "${var.droplets[count.index].hostname}.${device.value.name}"
                pool    = "${lxd_storage_pool.pac_pool.name}"
            }
        }
    }
}