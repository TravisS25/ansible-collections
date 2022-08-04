#!/usr/bin/python3

import subprocess
from distutils import core
from ansible.module_utils.basic import AnsibleModule
from ansible_collections.community.digitalocean.plugins.module_utils.digital_ocean import DigitalOceanHelper
import time

VOLUMES_STATES = ['present', 'absent']
VOLUMES_COMMANDS = ['create', 'attach', 'both']


def validate_input(module: AnsibleModule):
    if module.params['fail_api_call']:
        module.fail_json('Fail volume api call')

    if module.params['volume_state'] not in VOLUMES_STATES:
        module.fail_json('Invalid volume state "' +
                         module.params['volume_state'] + '".  Valid volume states are ' + str(VOLUMES_STATES))

    if module.params['volume_command'] not in VOLUMES_COMMANDS:
        module.fail_json('Invalid volume command "' +
                         module.params['volume_command'] + '".  Valid volume commands are ' + str(VOLUMES_COMMANDS))

    if module.params['block_size'] < 1:
        module.fail_json('Invalid volume size "' +
                         module.params['block_size'] + '".  Volume size must be a postive integer')

    if module.params['volume_command'] != 'create' and module.params['droplet_id'] is None:
        module.fail_json(
            '"droplet_id" variable is required when "volume_command" is set to "attached" or "both"'
        )

    if len(module.params['region_slugs']) == 0:
        module.fail_json(
            '"region_slugs" variable must be defined and a list with at least 1 entry',
        )

    if len(module.params['volume_names']) == 0:
        module.fail_json(
            '"volume_names" variable must be defined and a list with at least 1 entry',
        )

    if len(module.params['volume_objects']) == 0:
        module.fail_json(
            '"volume_objects" variable must be defined and a list with at least 1 entry',
        )

    for val in module.params['volume_objects']:
        if val['volume_name'] is None or len(val['volume_name']) < 3:
            module.fail_json(
                '"volume_objects" must contain key "volume_name" and have a length of at least 3 characters'
            )

    if module.params['volume_command'] != 'create' and module.params['droplet_id'] is None:
        module.fail_json(
            '"droplet_id" is required when "volume_command" is set to "attached" or "both"'
        )

    if module.params['volume_command'] != 'attach':
        dupVolumeName = ''

        for vn in module.params['server_volume_names']:
            for vo in module.params['volume_objects']:
                if vn == vo['volume_name']:
                    dupVolumeName = vn
                    break

            if vn != '':
                break

        if dupVolumeName != '':
            module.fail_json('Duplicate volume name ' + dupVolumeName)


def run_module():
    argument_spec = DigitalOceanHelper.digital_ocean_argument_spec()
    argument_spec.update(
        fail_api_call=dict(type="bool", default=False),
        region=dict(type="str", required=True),
        region_slugs=dict(type="list", required=True, default=[]),
        block_size=dict(type="int", required=True),
        volume_command=dict(type="str", required=True,
                            choices=VOLUMES_COMMANDS),
        volume_state=dict(type="str", required=True, choices=VOLUMES_STATES),
        volume_description=dict(type="str"),
        volume_objects=dict(type="list", default=[]),
        server_volume_names=dict(type="list", required=True, default=[]),
        droplet_id=dict(type="str"),
    )

    module = AnsibleModule(
        argument_spec=argument_spec,
    )

    validate_input(module)

    if module.params['run_type'] == 'local':
        subprocess.run(['vagrant', ''])
    else:
        module.exit_json('Successful')


def main():
    run_module()


if __name__ == '__main__':
    main()
