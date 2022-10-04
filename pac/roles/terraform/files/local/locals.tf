locals {
    domain                      = "pacdev.com"

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

    host_config                 = {
        "${var.dns_server_ip}"    = [
            "${local.dns_server_hostname}.${local.domain}",
        ],
        "${var.pac_server1_ip}"   = [
            "${local.minio1_fqdn}",
            "${local.server1_hostname}.${local.domain}",
        ],
        "${var.pac_server2_ip}"   = [
            "${local.minio2_fqdn}",
            "${local.server2_hostname}.${local.domain}",
            "${local.roach1_fqdn}",
        ],
        "${var.pac_server3_ip}"   = [
            "${local.minio3_fqdn}",
            "${local.server3_hostname}.${local.domain}",
            "${local.roach2_fqdn}",
        ],
        "${var.pac_server4_ip}"   = [
            "${local.minio4_fqdn}",
            "${local.server4_hostname}.${local.domain}",
            "${local.roach3_fqdn}",
        ],
    }

    disk_droplets   = [
        {
            ip                  = var.pac_server1_ip
            hostname            = local.server1_hostname
            user                = local.server_user
            cloud_init          = local.cloud_init
            specs               = local.minio_server_specs
            tls                 = [
                merge(local.default_minio_tls, {
                    common_name         = local.server1_fqdn
                    subject_alt_names   = ["DNS:${local.minio1_fqdn}"]
                }),
            ]
            docker_containers   = [
                local.alertmanager_docker,
                local.node_exporter_docker,
                local.grafana_docker,
                local.prometheus_docker,
                local.minio_docker,
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
        #             subject_alt_names   = ["DNS:${local.roach1_fqdn}"]
        #         }),
        #         merge(local.default_cockroach_client_tls,{
        #             common_name         = local.server2_fqdn
        #             subject_alt_names   = ["DNS:${local.roach1_fqdn}"]
        #         }),
        #     ]
        #     docker_containers   = [
        #         local.node_exporter_docker,
        #         local.init_cockroachdb_docker,
        #         local.minio_docker,
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
        #             subject_alt_names   = ["DNS:${local.roach2_fqdn}"]
        #         }),
        #         merge(local.default_cockroach_client_tls,{
        #             common_name         = local.server3_fqdn
        #             subject_alt_names   = ["DNS:${local.roach2_fqdn}"]
        #         }),
        #     ]
        #     docker_containers   = [
        #         local.node_exporter_docker,
        #         local.start_cockroachdb_docker,
        #         local.minio_docker,
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
        #             subject_alt_names   = ["DNS:${local.roach3_fqdn}"]
        #         }),
        #         merge(local.default_cockroach_client_tls,{
        #             common_name         = local.server4_fqdn
        #             subject_alt_names   = ["DNS:${local.roach3_fqdn}"]
        #         }),
        #     ]
        #     docker_containers   = [
        #         local.node_exporter_docker,
        #         local.start_cockroachdb_docker,
        #         local.minio_docker,
        #     ]
        # }
    ]           

    misc_droplets   = [
        {
            ip                  = var.dns_server_ip
            hostname            = local.dns_server_hostname
            user                = local.server_user
            cloud_init          = local.cloud_init
            specs               = local.specs
            docker_containers   = [
                local.coredns_docker
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
