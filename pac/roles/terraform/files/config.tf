locals {
    ///////////////////////////////////////////////////////
    // The following values SHOULD NOT CHANGE!!!
    ///////////////////////////////////////////////////////

    app_name        = "pac"
    vault_pki_path  = "${local.app_name}-pki"


    // -----------------------------------------------------

    server_user                 = "server"
    
    minio_name                  = "minio"
    cockroach_name              = "cockroachdb"
    server_name                 = "server"

    minio_mount_point           = "/mnt"
    storage_mount_point         = "/mnt/storage"

    dns_server_hostname         = "dns-server"
    dns_server_fqdn             = "${local.dns_server_hostname}.${local.domain}"

    server1_hostname            = "${local.server_name}1"
    server2_hostname            = "${local.server_name}2"
    server3_hostname            = "${local.server_name}3"
    server4_hostname            = "${local.server_name}4"

    server1_fqdn                = "${local.server1_hostname}.${local.domain}"
    server2_fqdn                = "${local.server2_hostname}.${local.domain}"
    server3_fqdn                = "${local.server3_hostname}.${local.domain}"
    server4_fqdn                = "${local.server4_hostname}.${local.domain}"

    cockroach1_hostname         = "${local.cockroach_name}1"
    cockroach2_hostname         = "${local.cockroach_name}2"
    cockroach3_hostname         = "${local.cockroach_name}3"

    cockroach1_fqdn             = "${local.cockroach1_hostname}.${local.domain}"
    cockroach2_fqdn             = "${local.cockroach2_hostname}.${local.domain}"
    cockroach3_fqdn             = "${local.cockroach3_hostname}.${local.domain}"

    minio1_hostname             = "${local.minio_name}1"
    minio2_hostname             = "${local.minio_name}2"
    minio3_hostname             = "${local.minio_name}3"
    minio4_hostname             = "${local.minio_name}4"

    minio1_fqdn                 = "${local.minio1_hostname}.${local.domain}"
    minio2_fqdn                 = "${local.minio2_hostname}.${local.domain}"
    minio3_fqdn                 = "${local.minio3_hostname}.${local.domain}"
    minio4_fqdn                 = "${local.minio4_hostname}.${local.domain}"

    minio1_path                 = "${local.minio_mount_point}/${local.minio1_hostname}"
    minio2_path                 = "${local.minio_mount_point}/${local.minio2_hostname}"
    minio3_path                 = "${local.minio_mount_point}/${local.minio3_hostname}"
    minio4_path                 = "${local.minio_mount_point}/${local.minio4_hostname}"

    alertmanager_config_file    = "/etc/alertmanager/alertmanager.yml"
    prometheus_config_dir       = "/etc/prometheus/"
    coredns_config_file         = "/etc/coredns/Corefile"

    home_dir                    = "/home/${local.server_user}"

    csr_dir                     = "${local.home_dir}/.csrs"
    cockroach_certs_dir         = "${local.home_dir}/.cockroach-certs"
    minio_certs_dir             = "${local.home_dir}/.minio/certs"

    minio_key                   = {
        dir_path    = local.minio_certs_dir
        filename    = "private.key"
    }

    minio_cert                  = {
        dir_path    = local.minio_certs_dir
        filename    = "public.crt"
    }

    cockroach_node_cert         = {
        dir_path    = local.cockroach_certs_dir
        filename    = "node.crt"
    }

    cockroach_node_key          = {
        dir_path    = local.cockroach_certs_dir
        filename    = "node.key"
    }

    cockroach_client_cert       = {
        dir_path    = local.cockroach_certs_dir
        filename    = "client.${local.server_user}.crt"
    }

    cockroach_client_key        = {
        dir_path    = local.cockroach_certs_dir
        filename    = "client.${local.server_user}.key"
    }

    default_cockroach_node_tls  = {
        cert    = local.cockroach_node_cert
        key     = local.cockroach_node_key
        csr     = {
            dir_path    = local.csr_dir
            filename    = "node.csr"
        }
    }

    default_cockroach_client_tls    = {
        cert    = local.cockroach_client_cert
        key     = local.cockroach_client_key
        csr     = {
            dir_path    = local.csr_dir
            filename    = "client.csr"
        }
    }

    default_minio_tls           =  {
        cert    = local.minio_cert
        key     = local.minio_key
        csr     = {
            dir_path    = local.csr_dir
            filename    = "minio.csr"
        }
    }                 

    coredns_docker              = {
        name        = "coredns"
        root_var    = {
            action      = "start"
            config_file = local.coredns_config_file
        }
    }

    minio_docker                = {
        name        = "minio"
        root_var    = {
            hostname            = local.minio_name
            action              = "start"
            storage_path        = "${local.minio_mount_point}${local.minio_name}"
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
            storage_path    = "${local.storage_mount_point}/node_exporter"
        }
    }

    grafana_docker              = {
        name        = "grafana"
        root_var    = {
            action          = "start"
            storage_path    = "${local.storage_mount_point}/grafana"
        }
    }

    prometheus_docker           = {
        name        = "grafana"
        root_var    = {
            action          = "start"
            storage_path    = "${local.storage_mount_point}/promethues"
            config_dir      = local.prometheus_config_dir
        }
    }

    subset_cockroachdb_docker   = {
        action          = "start"
        storage_path    = "${local.storage_mount_point}/cockroachdb"
        start_command   = "start --insecure --join=192.168.3.5,192.168.3.6,192.168.3.7"
    }

    start_cockroachdb_docker    = {
        name        = "${local.cockroach_name}"
        root_var    = local.subset_cockroachdb_docker
    }

    init_cockroachdb_docker     = {
        name        = "${local.cockroach_name}"
        root_var    = "${merge(local.subset_cockroachdb_docker, tomap({"init_command" = "init --insecure"}))}"
    }

    alertmanager_docker         = {
        name        = "alertmanager"
        root_var    = {
            action         = "start"
            config_file    = local.alertmanager_config_file
        }
    }

    redis_docker                = {
        name        = "redis"
        root_var    = {
            action  = "start"
        }
    }

    vault_settings              = {
        pki_path    = "${local.vault_pki_path}"
        policies    = [
            {
                name    = "cert-pki"
                rule    = <<-EOT
                    path "${local.vault_pki_path}/+/${local.cockroach_name}" {
                        capabilities = ["create", "read", "update", "patch", "delete", "list"]
                    }
                EOT
            },
            {
                name    = "${local.cockroach_name}-pki"
                rule    = <<-EOT
                    path "${local.vault_pki_path}/+/${local.cockroach_name}" {
                        capabilities = ["create", "read", "update", "patch", "delete", "list"]
                    }
                EOT
            },
        ]
    }
}
