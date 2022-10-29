locals {
    # domain                      = "pacdev.com"

    minio_disk_size             = 1

    specs                       = {
        memory  = 2048
        cpus    = 1
    }

    minio_server_specs          = {
        memory  = 2048
        cpus    = 1
        disks   = [
            {
                name    = local.minio1_hostname
                path    = local.minio1_path
                size    = local.minio_disk_size
            },
            {
                name    = local.minio2_hostname
                path    = local.minio2_path
                size    = local.minio_disk_size
            },
            {
                name    = local.minio3_hostname
                path    = local.minio3_path
                size    = local.minio_disk_size
            },
            {
                name    = local.minio4_hostname
                path    = local.minio4_path
                size    = local.minio_disk_size
            },
        ]
    }

    cloud_init                  = {
        user_data       = {
            users           = [
                {
                    name            = local.server_user
                    primary_group   = local.server_user
                    groups          = "sudo"
                    sudo            = "ALL=(ALL) NOPASSWD:ALL"
                    shell           = "/bin/bash"
                }
            ]
        },
        network_config  = {
            network = {
                version     = 2
                ethernets   = {
                    eth0    = {
                        dhcp4           = true
                        dhcp4-overrides = {
                            use-dns    = false
                        }
                        nameservers     = {
                            addresses   = [
                                var.dns_server_ip,
                                "8.8.8.8"
                            ]
                        }
                    }
                }
            }
        }
    }

    disk_droplets   = [
        {
            ip                  = var.pac_server1_ip
            hostname            = local.server1_hostname
            user                = local.server_user
            cloud_init          = local.cloud_init
            specs               = local.minio_server_specs
            deploy   = [
                local.vault_deploy,
                local.alertmanager_deploy,
                local.node_exporter_deploy,
                local.grafana_deploy,
                local.prometheus_deploy,
                local.minio_deploy,
            ]
        },
        # {
        #     ip                  = var.pac_server2_ip
        #     hostname            = local.server2_hostname
        #     user                = local.server_user
        #     cloud_init          = local.cloud_init
        #     specs               = local.minio_server_specs
        #     tls                 = [
        #         merge(local.default_minio_tls, {
        #             common_name         = local.server2_fqdn
        #             subject_alt_names   = ["DNS:${local.minio2_fqdn}"]
        #         }),
        #         merge(local.default_cockroach_node_tls,{
        #             common_name         = local.server2_fqdn
        #             subject_alt_names   = ["DNS:${local.cockroach1_fqdn}"]
        #         }),
        #         merge(local.default_cockroach_client_tls,{
        #             common_name         = local.server2_fqdn
        #             subject_alt_names   = ["DNS:${local.cockroach1_fqdn}"]
        #         }),
        #     ]
        #     deploy   = [
        #         local.node_exporter_deploy,
        #         local.init_cockroachdb_deploy,
        #         local.minio_deploy,
        #     ]
        # },
        # {
        #     ip                  = var.pac_server3_ip
        #     hostname            = local.server3_hostname
        #     user                = local.server_user
        #     cloud_init          = local.cloud_init
        #     specs               = local.minio_server_specs
        #     tls                 = [
        #         merge(local.default_minio_tls, {
        #             common_name         = local.server3_fqdn
        #             subject_alt_names   = ["DNS:${local.minio3_fqdn}"]
        #         }),
        #         merge(local.default_cockroach_node_tls,{
        #             common_name         = local.server3_fqdn
        #             subject_alt_names   = ["DNS:${local.cockroach2_fqdn}"]
        #         }),
        #         merge(local.default_cockroach_client_tls,{
        #             common_name         = local.server3_fqdn
        #             subject_alt_names   = ["DNS:${local.cockroach2_fqdn}"]
        #         }),
        #     ]
        #     deploy   = [
        #         local.node_exporter_deploy,
        #         local.cockroachdb_deploy,
        #         local.minio_deploy,
        #     ]
        # },
        # {
        #     ip                  = var.pac_server4_ip
        #     hostname            = local.server4_hostname
        #     user                = local.server_user
        #     cloud_init          = local.cloud_init
        #     specs               = local.minio_server_specs
        #     tls                 = [
        #         merge(local.default_minio_tls, {
        #             common_name         = local.server4_fqdn
        #             subject_alt_names   = ["DNS:${local.minio4_fqdn}"]
        #         }),
        #         merge(local.default_cockroach_node_tls,{
        #             common_name         = local.server4_fqdn
        #             subject_alt_names   = ["DNS:${local.cockroach3_fqdn}"]
        #         }),
        #         merge(local.default_cockroach_client_tls,{
        #             common_name         = local.server4_fqdn
        #             subject_alt_names   = ["DNS:${local.cockroach3_fqdn}"]
        #         }),
        #     ]
        #     deploy   = [
        #         local.node_exporter_deploy,
        #         local.cockroachdb_deploy,
        #         local.minio_deploy,
        #     ]
        # }
    ]           

    misc_droplets   = [
        {
            ip                  = var.dns_server_ip
            hostname            = local.dns_hostname
            user                = local.server_user
            cloud_init          = local.cloud_init
            specs               = local.specs
            deploy   = [
                local.coredns_deploy
            ]
        },
    ]

    #droplets = local.misc_droplets
    droplets = concat(local.misc_droplets, local.disk_droplets)

    droplet_disks = flatten([
        for droplet in local.disk_droplets : [
            for disk in droplet.specs.disks : {
                hostname    = droplet.hostname
                disk_path   = disk.path
                disk_name   = disk.name
                disk_size   = disk.size
            }
        ]
    ])
}
