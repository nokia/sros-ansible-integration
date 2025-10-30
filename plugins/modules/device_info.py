# (c) 2025 Nokia
#
# Licensed under the BSD 3 Clause license
# SPDX-License-Identifier: BSD-3-Clause

DOCUMENTATION = '''
---
module: nokia.sros.device_info
author: Nokia
short_description: Return device information
'''

EXAMPLES = '''
- name: get device info
  nokia.sros.device_info:
'''

RETURN = '''
output:
  description: device information gathered
  returned: success
  type: dict
  sample:
    network_os: "nokia.sros.classic"
    network_os_hostname: "Berlin"
    network_os_model: "7750 SR-12"
    network_os_version: "B-19.5.R2"
    sros_config_mode: "classic"
'''

from ansible.module_utils.basic import AnsibleModule
from ansible.module_utils.connection import Connection


def main():
    argument_spec = dict()
    module = AnsibleModule(argument_spec=argument_spec)
    connection = Connection(module._socket_path)

    device_info = connection.get_device_info() or {}
    warnings = device_info.pop('warnings', None)
    if warnings:
        if not isinstance(warnings, (list, tuple, set)):
            warnings = [warnings]
        for warning in warnings:
            if warning:
                module.warn(str(warning))

    module.exit_json(changed=False, output=device_info)


if __name__ == '__main__':
    main()
