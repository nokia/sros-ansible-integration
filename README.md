![NOKIA](media/logo.png)

---

# Ansible Collection – `nokia.sros`

The [Ansible](https://docs.ansible.com/ansible/latest/network/index.html) [`nokia.sros` collection](https://galaxy.ansible.com/ui/repo/published/nokia/sros) provides **CLI** and **[NETCONF](https://www.rfc-editor.org/rfc/rfc6241.html)** plugins for Nokia **SR OS** devices.
These plugins act as device drivers enabling the use of Ansible networking modules such as `cli_config` and `cli_command` from the [`ansible.netcommon` collection](https://docs.ansible.com/ansible/latest/collections/ansible/netcommon/index.html).
The collection also provides device information and capability discovery.

This project is a **Nokia-initiated open-source effort**, licensed under the [BSD 3-Clause License](https://raw.githubusercontent.com/nokia/sros-ansible/refs/heads/master/LICENSE), designed to promote programmable network automation using standard IT tools.
We welcome contributions from the community — including tutorials, real-world playbook examples, feature requests, bug reports, or code enhancements.

> **Notes**
>
> * Ansible collections are distributed via [Ansible Galaxy](https://galaxy.ansible.com/).
> * For Nokia SR Linux and data-center switches, use the [`nokia.srlinux`](https://galaxy.ansible.com/nokia/srlinux) collection.
> * For OpenConfig [gNMI](http://www.openconfig.net/projects/gnmi/gnmi)-based automation, use the [`nokia.grpc`](https://galaxy.ansible.com/ui/repo/published/nokia/grpc) collection.

---

## Requirements

* **Python** 3.11 or newer
* **Python libraries:**

  * [ansible-pylibssh](https://pypi.org/project/ansible-pylibssh)
  * [jxmlease](https://pypi.org/project/jxmlease)
  * [ncclient](https://pypi.org/project/ncclient)
* **Ansible Core 2.13** or newer

---

## Supported SR OS Versions

Tested with **SR OS 25.7**.
Other versions may work but have not been explicitly validated.

---

## Installation

Use the following recipe to create a ready-to-use virtual environment for SR OS Ansible automation:

```bash
python -m venv .venv
source .venv/bin/activate

python -m pip install --upgrade pip
python -m pip install ansible-core ansible-pylibssh jxmlease ncclient

ansible-galaxy collection install ansible.netcommon nokia.sros --force-with-deps
```

---

## Usage

In your Ansible inventory, specify the network OS for your SR OS hosts:

```yaml
ansible_network_os: nokia.sros.<mode>
```

Where `<mode>` can be `classic`, `md`, or `light`.

Detailed tutorials are available on the
**[Nokia Network Developer Portal](https://network.developer.nokia.com/sr/learn/sr-os-ansible)**.

---

## Example Playbooks

This repository contains sample playbooks demonstrating how to use the collection.
They can also serve as regression tests.

### Classic CLI

* [sros_classic_cli_command_demo.yml](tests/playbooks/sros_classic_cli_command_demo.yml)
* [sros_classic_cli_config_demo.yml](tests/playbooks/sros_classic_cli_config_demo.yml)
* [sros_classic_cli_backup_restore_demo.yml](tests/playbooks/sros_classic_cli_backup_restore_demo.yml)

### MD-CLI

* [sros_mdcli_command_demo.yml](tests/playbooks/sros_mdcli_command_demo.yml)
* [sros_mdcli_config_demo.yml](tests/playbooks/sros_mdcli_config_demo.yml)
* [sros_mdcli_backup_restore_demo.yml](tests/playbooks/sros_mdcli_backup_restore_demo.yml)

### NETCONF

* [sros_nc_state_demo.yml](tests/playbooks/sros_nc_state_demo.yml)

### Device Info

* [sros_cli_device_info.yml](tests/playbooks/sros_cli_device_info.yml)
* [sros_nc_device_info.yml](tests/playbooks/sros_nc_device_info.yml)

---

## Modules

The module **`nokia.sros.device_info`** retrieves information about the connected SR OS device.
It works with both CLI and NETCONF connections.

**Example output:**

```yaml
output:
  network_os: "nokia.sros.classic"
  network_os_hostname: "Antwerp"
  network_os_model: "7750 SR-12"
  network_os_platform: "Nokia 7x50"
  network_os_version: "B-19.5.R2"
  sros_config_mode: "classic"
```

---

## Roles

*None.*

---

## Plugins

| Network OS         | terminal | cliconf | netconf |
| ------------------ | :------: | :-----: | :-----: |
| nokia.sros.md      |     ✅    |    ✅    |    ✅    |
| nokia.sros.classic |     ✅    |    ✅    |    –    |
| nokia.sros.light   |     ✅    |    ✅    |    –    |

---

## Implementation Details

### Classic Mode

In **Classic CLI** mode, the plugin leverages the SR OS built-in **rollback** feature.
Ensure that rollback storage is properly configured, for example:

```text
A:Antwerp# file md cf3:/rollbacks
*A:Antwerp# configure system rollback rollback-location cf3:/rollbacks/config
INFO: CLI No checkpoints currently exist at the rollback location.
*A:Antwerp# admin rollback save
Saving rollback configuration to cf3:/rollbacks/config.rb... OK
*A:Antwerp#
```

> **Note**
> Use `nokia.sros.light` for nodes that do not support rollback or where rollback usage is undesired.

#### Snapshot / Rollback Workflow

* A temporary rollback checkpoint is created at the start of each `cli_config` operation.
* If a configuration error occurs, the plugin reverts to the pre-operation checkpoint (**rollback-on-error**).
* If successful, the plugin compares the new configuration to the previous checkpoint to populate `changed` and `diff` results.
* With the `--check` (dry-run) option, configuration changes are applied, validated, and then immediately rolled back — providing syntax checks and diff output.
* After completion, the temporary checkpoint is deleted to keep rollback history clean.

> **⚠️ Warnings**
>
> * Dry-run temporarily activates configuration changes before rolling them back.
>   Be aware that this can cause brief service impact.
> * `rollback-on-error` may have side effects on modules such as BGP within VPRNs, which revert to default state (`shutdown`) before rollback is applied.
>   Refer to the *Basic System Configuration Guide* for details.

#### Restrictions

* Some platforms may not support checkpoint/rollback.
* All changes are written directly to the running configuration.
* Operation type `replace` is not supported.
* The oldest rollback checkpoint may be deleted after plugin execution.

---

### Light Mode

The **Light Mode** (`nokia.sros.light`) is a simplified CLI implementation used when rollback is not available or not desired.
It determines configuration changes based on the **prompt change indicator** (appearance of `*` in the prompt).

#### Restrictions

* If the device already has unsaved changes before a task runs, the playbook will treat it as `changed`.
* `--diff` and `--check` modes are not supported.
