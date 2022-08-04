#!/usr/bin/python

from tkinter.tix import Tree
from ansible.module_utils.basic import AnsibleModule
from ansible_collections.community.digitalocean.plugins.module_utils.digital_ocean import DigitalOceanHelper
from ansible_collections.community.digitalocean.plugins.modules.digital_ocean_droplet import core


def run_module():
    argument_spec = DigitalOceanHelper.digital_ocean_argument_spec()
    argument_spec.update(
        state=dict(
            choices=["present", "absent", "active", "inactive"], default="present"
        ),
        name=dict(type="str"),
        size=dict(aliases=["size_id"]),
        image=dict(aliases=["image_id"]),
        region=dict(aliases=["region_id"]),
        ssh_keys=dict(type="list", elements="str", no_log=False),
        private_networking=dict(type="bool", default=False),
        vpc_uuid=dict(type="str"),
        backups=dict(type="bool", default=False),
        monitoring=dict(type="bool", default=False),
        id=dict(aliases=["droplet_id"], type="int"),
        user_data=dict(default=None),
        ipv6=dict(type="bool", default=False),
        volumes=dict(type="list", elements="str"),
        tags=dict(type="list", elements="str"),
        wait=dict(type="bool", default=True),
        wait_timeout=dict(default=120, type="int"),
        unique_name=dict(type="bool", default=False),
        resize_disk=dict(type="bool", default=False),
        project_name=dict(type="str", aliases=[
            "project"], required=False, default=""),
        firewall=dict(type="list", elements="str", default=None),
        sleep_interval=dict(default=10, type="int"),
        prod=dict(type="bool", default=False),
        droplet_type=dict(
            choices=["web_server", "db_server",
                     "storage_server", "proxy_server"],
        ),
    )

    module = AnsibleModule(
        argument_spec=argument_spec,
        required_one_of=(["id", "name"],),
        required_if=(
            [
                ("state", "present", ["name", "size", "image", "region"]),
                ("state", "active", ["name", "size", "image", "region"]),
                ("state", "inactive", ["name", "size", "image", "region"]),
                ("state", "absent", ["name", "unique_name"]),
            ]
        ),
        supports_check_mode=True,
    )

    if module.params['run_type']:
        core(module)
    else:
        print('Hitting non production module')
        module.exit_json(**module.params)


def main():
    run_module()


if __name__ == '__main__':
    main()
