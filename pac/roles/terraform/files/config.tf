locals {
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
}