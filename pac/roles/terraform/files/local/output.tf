
output "local_config" {
    value   = {
        droplets        = local.droplets
        vault_settings  = local.vault_settings
    }
}