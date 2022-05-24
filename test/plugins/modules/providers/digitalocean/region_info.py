#!/usr/bin/python3

from distutils import core
from ansible.module_utils.basic import AnsibleModule
from ansible_collections.community.digitalocean.plugins.module_utils.digital_ocean import DigitalOceanHelper


def run_module():
    argument_spec = DigitalOceanHelper.digital_ocean_argument_spec()
    argument_spec.update(
        fail_api_call=dict(type="bool", default=False),
    )

    module = AnsibleModule(
        argument_spec=argument_spec,
    )

    if module.params['fail_api_call']:
        module.fail_json('Fail region info')

    rest = DigitalOceanHelper(module)

    base_url = "regions?"
    regions = rest.get_paginated_data(
        base_url=base_url, data_key_name="regions")

    module.exit_json(changed=False, data=regions)


def main():
    run_module()


if __name__ == '__main__':
    main()
