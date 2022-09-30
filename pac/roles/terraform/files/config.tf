variable "roach_hosts" {
    type        = string
    nullable    = false
    description = "Comma seperated string of all hosts in cockroachdb cluster"
}

locals {
    minio1_path                 = "/mnt/minio1"
    minio2_path                 = "/mnt/minio2"
    minio3_path                 = "/mnt/minio3"
    minio4_path                 = "/mnt/minio4"

    ca_server_ip                = "192.168.3.2"
    ca_server_hostname          = "ca-server"

    dns_server_ip               = "192.168.3.3"
    dns_server_hostname         = "dns-server"

    pac_server1_ip              = "192.168.3.4"
    pac_server1_hostname        = "pac_server1"

    pac_server2_ip              = "192.168.3.5"
    pac_server2_hostname        = "pac_server2"

    pac_server3_ip              = "192.168.3.5"
    pac_server3_hostname        = "pac_server3"

    pac_server4_ip              = "192.168.3.6"
    pac_server4_hostname        = "pac_server4"

    pac_user                    = "pac-user"
    pac_domain                  = "pacdev.com"

    alertmanager_config_file    = "/etc/alertmanager/alertmanager.yml"
    prometheus_config_file      = "/etc/prometheus/prometheus.yml"
    coredns_config_file         = "/etc/coredns/Corefile"

    ca_server                   = {
        ip  = "${local.ca_server_ip}"
    }

    coredns_docker              = {
        name        = "coredns"
        root_var    = {
            action      = "start"
            config_file = "${local.coredns_config_file}"
        }
    }

    minio_docker                = {
        name        = "minio"
        root_var    = {
            hostname            = "minio"
            action              = "start"
            storage_path        = "/mnt/minio"
            protocol            = "http"
            distributed_mode    = {
                num_of_drives   = 4
                num_of_hosts    = 4
            }
        }
    }

    node_exporter_docker        = {
        name        = "node_exporter"
        root_var    = {
            action          = "start"
            storage_path    = "/mnt/storage/node_exporter"
        }
    }

    grafana_docker              = {
        name        = "grafana"
        root_var    = {
            action          = "start"
            storage_path    = "/mnt/storage/grafana"
        }
    }

    prometheus_docker           = {
        name        = "grafana"
        root_var    = {
            action          = "start"
            storage_path    = "/mnt/storage/promethues"
            config_dir      = "${local.prometheus_config_file}"
        }
    }

    subset_cockroachdb_docker   = {
        action          = "start"
        storage_path    = "/mnt/storage/cockroachdb"
        start_command   = "start --insecure --join=${var.roach_hosts}"
    }

    start_cockroachdb_docker    = {
        name        = "cockroachdb"
        root_var    = "${local.subset_cockroachdb_docker}"
    }

    init_cockroachdb_docker     = {
        name        = "cockroachdb"
        root_var    = "${merge(local.subset_cockroachdb_docker, map("init_command", "init --insecure"))}"
    }

    alertmanager_docker         = {
        name        = "alertmanager"
        root_var    = {
            action         = "start"
            config_file    = "${local.alertmanager_config_file}"
        }
    }

    redis_docker                = {
        name        = "redis"
        root_var    = {
            action  = "start"
        }
    }

    specs                       = {
        memory  = 2048
        cpus    = 1
    }

    minio_server_specs          = {
        memory  = 2048
        cpus    = 1
        disks   = [
            {
                name    = "minio1"
                path    = "${local.minio1_path}"
                size    = 1
            },
            {
                name    = "minio2"
                path    = "${local.minio2_path}"
                size    = 1
            },
            {
                name    = "minio3"
                path    = "${local.minio3_path}"
                size    = 1
            },
            {
                name    = "minio4"
                path    = "${local.minio4_path}"
                size    = 1
            },
        ]
    }

    cloud_init                  = {
        user_data       = {
            users   = [
                {
                    name            = "${local.pac_user}"
                    primary_group   = "${local.pac_user}"
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
                            user-dns    = "no"
                        }
                        nameservers     = {
                            addresses   = [
                                "${local.dns_server_ip}",
                                "8.8.8.8"
                            ]
                        }
                    }
                }
            }
        }
    }
}

output "config" {
    value   = {
        terraform   = {}
        droplets    = [
            {
                ip                  = "${local.ca_server_ip}"
                hostname            = "${local.ca_server_hostname}"
                user                = "${local.pac_user}"
                cloud_init          = "${local.cloud_init}"
                specs               = "${local.specs}"
                ca                  = {
                    server  = {}
                }
            },
            {
                ip                  = "${local.dns_server_ip}"
                hostname            = "${local.dns_server_hostname}"
                user                = "${local.pac_user}"
                cloud_init          = "${local.cloud_init}"
                specs               = "${local.specs}"
                transfers           = [
                    {
                        source_env_var  = "PAC_DNS_COREFILE"
                        dest            = "${coredns_config_file}"
                    },
                    {
                        source_env_var  = "PAC_DNS_HOST_FILE"
                        dest            = "/etc/coredns/hosts/pacdev.com"
                    },
                ]
                docker_containers   = [
                    "${local.coredns_docker}"
                ]
            },
            {
                ip                  = "${local.pac_server1_ip}"
                hostname            = "${local.pac_server1_ip}"
                user                = "${local.pac_user}"
                cloud_init          = "${local.cloud_init}"
                specs               = "${local.specs}"
                transfers           = [
                    {
                        source_env_var  = "PAC_ALERT_MANAGER_CONFIG_FILE"
                        dest            = "${alertmanager_config_file}"
                    },
                    {
                        source_env_var  = "PAC_PROMETHEUS_CONFIG_DIR"
                        dest            = "${prometheus_config_dir}"
                    },
                ]
                ca                  = {
                    client  = {
                        ca_server           = "${local.ca_server}"
                        subject_alt_names   = [
                            "DNS:minio1.pacdev.com",
                            "DNS:pac-server1.pacdev.com"
                        ]
                    }
                }
                docker_containers   = [
                    "${local.alertmanager_docker}",
                    "${local.node_exporter_docker}",
                    "${local.grafana_docker}",
                    "${local.prometheus_docker}",
                    "${local.minio_docker}",
                ]
            },
            {
                ip                  = "${local.pac_server2_ip}"
                hostname            = "${local.pac_server2_ip}"
                user                = "${local.pac_user}"
                cloud_init          = "${local.cloud_init}"
                specs               = "${local.specs}"
                ca                  = {
                    client  = {
                        ca_server           = "${local.ca_server}"
                        subject_alt_names   = [
                            "DNS:minio2.pacdev.com",
                            "DNS:roach1.pacdev.com",
                            "DNS:pac-server2.pacdev.com"
                        ]
                    }
                }
                docker_containers   = [
                    "${local.node_exporter_docker}",
                    "${local.init_cockroachdb_docker}",
                    "${local.minio_docker}",
                ]
            },
            {
                ip                  = "${local.pac_server3_ip}"
                hostname            = "${local.pac_server3_ip}"
                user                = "${local.pac_user}"
                cloud_init          = "${local.cloud_init}"
                specs               = "${local.specs}"
                ca                  = {
                    client  = {
                        ca_server           = "${local.ca_server}"
                        subject_alt_names   = [
                            "DNS:minio3.pacdev.com",
                            "DNS:roach2.pacdev.com",
                            "DNS:pac-server3.pacdev.com"
                        ]
                    }
                }
                docker_containers   = [
                    "${local.node_exporter_docker}",
                    "${local.start_cockroachdb_docker}",
                    "${local.minio_docker}",
                ]
            },
            {
                ip                  = "${local.pac_server4_ip}"
                hostname            = "${local.pac_server4_ip}"
                user                = "${local.pac_user}"
                cloud_init          = "${local.cloud_init}"
                specs               = "${local.specs}"
                ca                  = {
                    client  = {
                        ca_server           = "${local.ca_server}"
                        subject_alt_names   = [
                            "DNS:minio4.pacdev.com",
                            "DNS:roach3.pacdev.com",
                            "DNS:pac-server4.pacdev.com"
                        ]
                    }
                }
                docker_containers   = [
                    "${local.node_exporter_docker}",
                    "${local.start_cockroachdb_docker}",
                    "${local.minio_docker}",
                ]
            },
        ]
    }
}