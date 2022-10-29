
output "local_config" {
    value   = {
        droplets            = local.droplets
        deploy_settings     = {
            minio           = local.minio_deploy
            node_exporter   = local.node_exporter_deploy
            grafana         = local.grafana_deploy
            prometheus      = local.prometheus_deploy
            cockroachdb     = local.cockroachdb_deploy
            alertmanager    = local.alertmanager_deploy
            vault           = local.vault_deploy
        }
    }
}