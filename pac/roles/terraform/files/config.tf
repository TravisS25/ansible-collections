locals {
    ///////////////////////////////////////////////////////
    // The following values SHOULD NOT CHANGE!!!
    ///////////////////////////////////////////////////////

    domain                          = "pickacontractor.com"
    app_name                        = "pac"
    cert_issuer_policy              = "${local.app_name}-cert-issuer"
    pac_pki_role                    = local.app_name
    
    root_pki_mount_point            = "${local.app_name}/root-pki"
    int_pki_mount_point             = "${local.app_name}/int-pki"
    app_role_mount_path             = "${local.app_name}/approle"

    deploy_policy                   = "${local.app_name}-deploy"
    deploy_token_role               = "${local.app_name}-deploy"
    deploy_app_role                 = "${local.app_name}-deploy"

    local_token_role                = "local"
    
    minio_num_of_drives_per_host    = 4
    minio_num_of_hosts              = 4
    minio_size_of_drive             = 20

    minio_app_role                  = local.minio_hostname
    cockroachdb_cert_app_role       = "${local.cockroachdb_hostname}-cert"
    prometheus_app_role             = local.prometheus_hostname
    grafana_app_role                = local.grafana_hostname
    alertmanager_app_role           = local.alertmanager_hostname
    vault_app_role                  = local.vault_hostname

    // -----------------------------------------------------

    ///////////////////////////////////////////////////////
    // The following values can be updated
    ///////////////////////////////////////////////////////

    root_pki_default_lease_ttl      = "87600h"
    int_pki_default_lease_ttl       = "43800h"
    minio_host_sets                 = 1


    // -----------------------------------------------------

    minio_hostname              = "minio"
    cockroachdb_hostname        = "cockroachdb"
    prometheus_hostname         = "prometheus"
    grafana_hostname            = "grafana"
    alertmanager_hostname       = "alertmanager"
    vault_hostname              = "vault"
    coredns_hostname            = "coredns"
    node_exporter_hostname      = "node_exporter"
    redis_hostname              = "redis"

    vault_fqdn                  = "${local.vault_hostname}.${local.domain}"
    cockroachdb_fqdn            = "${local.cockroachdb_hostname}.${local.domain}"

    minio_pki_name              = "${local.minio_hostname}-pki"
    cockroachdb_pki_name        = "${local.cockroachdb_hostname}-pki"
    prometheus_pki_name         = "${local.prometheus_hostname}-pki"
    grafana_pki_name            = "${local.grafana_hostname}-pki"
    alertmanager_pki_name       = "${local.alertmanager_hostname}-pki"
    vault_pki_name              = "${local.vault_hostname}-pki"

    server_name                 = "server"
    server_user                 = "user"

    minio_mount_path           = "/mnt/${local.minio_hostname}"
    storage_mount_path         = "/mnt/storage"

    alertmanager_config_file    = "/etc/alertmanager/alertmanager.yml"
    prometheus_config_dir       = "/etc/prometheus/"
    coredns_config_file         = "/etc/coredns/Corefile"
    vault_config_dir            = "/etc/vault/"

    home_dir                    = "/home/${local.server_user}"

    csr_dir                     = "${local.home_dir}/.csrs"
    cockroach_certs_dir         = "${local.home_dir}/.cockroach-certs"
    minio_certs_dir             = "${local.home_dir}/.minio/certs"

    root_pki_ca_url_path        = "/${local.root_pki_mount_point}/cert/ca"
    root_pki_crl_url_path       = "/${local.root_pki_mount_point}/cert/crl"

    vault_settings              = {
        // ip  <--  Will be determined at runtime by ansible
        port            = ":8200"
        token           = var.vault_token
        cert_settings   = {
            issue_role              = local.app_name 
            int_pki_mount_point     = local.int_pki_mount_point 
        }
    }

    # vault_cert_settings              = {
    #     issue_role          = local.app_name
    #     int_pki_mount_point = local.int_pki_mount_point
    #     ca_url_path         = local.root_pki_ca_url_path
    # }

    coredns_deploy              = {
        action      = "restart"
        config_file = local.coredns_config_file
    }

    minio_deploy                = {
        hostname            = local.minio_hostname
        action              = "restart"
        storage_path        = local.minio_mount_path
        protocol            = "https"
        distributed_mode    = {
            num_of_drives   = local.minio_num_of_drives_per_host
            num_of_hosts    = local.minio_num_of_hosts
        }
    }

    node_exporter_deploy        = {
        action          = "restart"
        storage_path    = "${local.storage_mount_path}/${local.node_exporter_hostname}"
    }

    grafana_deploy              = {
        action          = "restart"
        storage_path    = "${local.storage_mount_path}/${local.grafana_hostname}"
    }

    prometheus_deploy           = {
        action          = "restart"
        storage_path    = "${local.storage_mount_path}/${local.prometheus_hostname}"
        config_dir      = local.prometheus_config_dir
    }

    cockroachdb_deploy    = {
        action                  = "restart"
        storage_path            = "${local.storage_mount_path}/${local.cockroachdb_hostname}"
        cockroach_certs_dir     = local.cockroach_certs_dir
        vault                   = local.vault_settings
        node_cert_request       = {
            alt_names       = local.cockroachdb_fqdn
        }
        client_cert_request     = {
            common_name     = local.server_user
            alt_names       = local.cockroachdb_fqdn
        }
    }

    alertmanager_deploy         = {
        action         = "restart"
        config_file    = local.alertmanager_config_file
    }

    redis_deploy                = {
        action  = "restart"
    }

    vault_deploy                = {
        action                  = "restart"
        host                    = "http://localhost:8200"
        local_keys_file_store   = pathexpand("~/.vault-keys")
        local_tokens_file_store = pathexpand("~/.vault-tokens")
        config_dir              = local.vault_config_dir
        storage_path            = "${local.storage_mount_path}/${local.vault_hostname}"
        pki_settings            = {
            root                = {
                mount_path      = local.root_pki_mount_point
                mount_api       = {
                    description             = "Pac root cert engine"
                    config                  = {
                        default_lease_ttl   = local.root_pki_default_lease_ttl
                        max_lease_ttl       = local.root_pki_default_lease_ttl
                        force_no_cache      = true
                    }
                }
                cert_api        = {
                    common_name             = local.domain
                }
                url_api         = {
                    issuing_certificates    = ["http://${local.vault_fqdn}${local.root_pki_ca_url_path}"]
                    crl_distribution_points = ["http://${local.vault_fqdn}${local.root_pki_crl_url_path}"]
                }
                role_api        = {
                    role_name               = "pac"
                    ttl                     = local.root_pki_default_lease_ttl
                    allowed_domains         = [local.domain]
                    allow_subdomains        = true
                }
            }
            int                 = {
                mount_path      = local.int_pki_mount_point
                mount_api       = {
                    description             = "Pac intermediate cert engine"
                    config                  = {
                        default_lease_ttl   = local.int_pki_default_lease_ttl
                        max_lease_ttl       = local.int_pki_default_lease_ttl
                        force_no_cache      = true
                    }
                }
                cert_api        = {
                    common_name             = local.domain
                }
                sign_cert_api   = {
                    common_name             = local.domain
                }
                url_api         = {
                    issuing_certificates    = ["http://${local.vault_fqdn}/v1/${local.int_pki_mount_point}/ca"]
                    crl_distribution_points = ["http://${local.vault_fqdn}/v1/${local.int_pki_mount_point}/crl"]
                }
                role_api        = {
                    role_name               = "pac"
                    ttl                     = local.int_pki_default_lease_ttl
                    allowed_domains         = [local.domain]
                }
            }
        }
        app_role_settings    = {
            mount_path      = local.app_role_mount_path
            roles           = [
                {
                    role_name               = local.cockroachdb_cert_app_role
                    secret_id_bound_cidrs   = [
                        127.0.0.1/32
                    ]
                    policies                = [
                        local.cert_issuer_policy
                    ]
                }
            ]
        }
        policy_settings      = {
            policies        = [
                {
                    name      = local.deploy_policy
                    policy    = <<-EOT
                        path "${local.app_name}/*" {
                            capabilities = ["create", "read", "update", "patch", "delete", "list"]
                        }

                        path "${local.app_name}/${local.root_pki_mount_point}/*" {
                            capabilities = ["read"]
                        }
                    EOT
                },
                # {
                #     name      = local.cert_issuer_policy
                #     policy    = <<-EOT
                #         path "${local.int_pki_mount_point}/issue/${local.pac_pki_role}/*" {
                #             capabilities = ["create"]
                #         }
                #     EOT
                # },
            ]
        }
        token_settings      = {
            roles   = [
                {
                    role_name           = local.local_token_role

                    // This will eventually be dynamic where only the vault server
                    // ip addresses will be set
                    token_bound_cidrs   = [
                        192.168.4.0/24,
                    ]
                }
            ]
            tokens   = [
                {
                    role_name           = local.local_token_role
                    display_name        = "pac"
                    policies    = [
                        local.deploy_policy
                    ]
                },
            ]
        }
        # policies    = [
        #     {
        #         name      = local.deploy_policy
        #         policy    = <<-EOT
        #             path "${local.app_name}/*" {
        #                 capabilities = ["create", "read", "update", "patch", "delete", "list"]
        #             }

        #             path "auth/token/create" {
        #                 capabilities = ["create", "read", "update", "patch", "delete", "list"]
        #             }
        #         EOT
        #     },
        #     {
        #         name      = local.cert_issuer_policy
        #         policy    = <<-EOT
        #             path "${local.int_pki_mount_point}/issue/${local.pac_pki_role}/*" {
        #                 capabilities = ["create"]
        #             }
        #         EOT
        #     },
        # ]
    }
}
