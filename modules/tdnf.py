#!/usr/bin/python
# -*- coding: utf-8 -*-

# (c) 2019, Anish Swaminathan <https://github.com/suezzelur>
#
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type


ANSIBLE_METADATA = {'metadata_version': '1.1',
                    'status': ['stableinterface'],
                    'supported_by': 'community'}


DOCUMENTATION = '''
---
module: tdnf
short_description: Tiny DNF package manager
description:
  - Manages rpm packages for VMware Photon OS.
author: "Anish Swaminathan"
version_added: "2.9"
options:
  name:
    description:
      - A package name, like C(foo), or multiple packages, like C(foo, bar).
    aliases:
      - pkg
  state:
    description:
      - Indicates the desired package(s) state.
      - C(present) ensures the package(s) is/are present.
      - C(absent) ensures the package(s) is/are absent.
      - C(latest) ensures the package(s) is/are present and the latest version(s).
    default: present
    choices: [ "present", "absent", "latest" ]
  update_cache:
    description:
      - Update repo metadata cache. Can be run with other steps or on it's own.
    type: bool
    default: 'no'
  upgrade:
    description:
      - Upgrade all installed packages to their latest version.
    type: bool
    default: 'no'
  enablerepo:
    description:
      - I(Repoid) of repositories to enable for the install/update operation.
        When specifying multiple repos, separate them with a ",".
  disablerepo:
    description:
      - I(Repoid) of repositories to disable for the install/update operation.
        When specifying multiple repos, separate them with a ",".
  conf_file:
    description:
      - The tdnf configuration file to use for the transaction.
  disable_gpg_check:
    description:
      - Whether to disable the GPG checking of signatures of packages being
        installed. Has an effect only if state is I(present) or I(latest).
    type: bool
    default: 'no'
  installroot:
    description:
      - Specifies an alternative installroot, relative to which all packages
        will be installed.
    default: "/"
  security_severity:
    description:
      - Specifies the CVSS v3 score above which to install updates for packages
  releasever:
    description:
      - Specifies an alternative release from which all packages will be
        installed.
  exclude:
    description:
      - Package name(s) to exclude when state=present, or latest. This can be a
        list or a comma separated string.
notes:
  - '"name" and "upgrade" are mutually exclusive.'
  - When used with a `loop:` each package will be processed individually, it is much more efficient to pass the list directly to the `name` option.
'''

EXAMPLES = '''
# Update repositories and install "foo" package
- tdnf:
    name: foo
    update_cache: yes

# Update repositories and install "foo" and "bar" packages
- tdnf:
    name: foo,bar
    update_cache: yes

# Remove "foo" package
- tdnf:
    name: foo
    state: absent

# Remove "foo" and "bar" packages
- tdnf:
    name: foo,bar
    state: absent

# Install the package "foo"
- tdnf:
    name: foo
    state: present

# Install the packages "foo" and "bar"
- tdnf:
    name: foo,bar
    state: present

# Update repositories and update package "foo" to latest version
- tdnf:
    name: foo
    state: latest
    update_cache: yes

# Update repositories and update packages "foo" and "bar" to latest versions
- tdnf:
    name: foo,bar
    state: latest
    update_cache: yes

# Update all installed packages to the latest versions
- tdnf:
    upgrade: yes

# Update repositories as a separate step
- tdnf:
    update_cache: yes

'''

import re
# Import module snippets.
from ansible.module_utils.basic import AnsibleModule

def update_package_db(module, exit):
    cmd = "%s makecache" % (TDNF_PATH)
    rc, stdout, stderr = module.run_command(cmd, check_rc=False)
    if rc != 0:
        module.fail_json(msg="could not update package db", stdout=stdout, stderr=stderr)
    elif exit:
        module.exit_json(changed=True, msg='updated package db', stdout=stdout, stderr=stderr)
    else:
        return True

def upgrade_packages(
    module,
    excludelist,
    disable_gpg_check,
    security_severity,
    releasever,
    conf_file):
    cmd = "%s upgrade -y" % (TDNF_PATH)
    if excludelist:
        cmd = "%s --exclude %s" % (cmd, ",".join(excludelist))
    if disable_gpg_check:
        cmd = "%s --nogpgcheck" % cmd
    if security_severity:
        cmd = "%s --sec-severity %s" % (cmd, security_severity)
    if releasever:
        cmd = "%s --releasever %s" % (cmd, releasever)
    if conf_file:
        cmd = "%s -c %s" % (cmd, conf_file)

    rc, stdout, stderr = module.run_command(cmd, check_rc=False)
    if rc != 0:
        module.fail_json(msg="failed to upgrade packages", stdout=stdout, stderr=stderr)
    module.exit_json(changed=True, msg="upgraded packages", stdout=stdout, stderr=stderr)


def install_packages(
            module,
            pkglist,
            enablerepolist,
            disablerepolist,
            excludelist,
            disable_gpg_check,
            installroot,
            releasever,
            conf_file):
    packages = " ".join(pkglist)
    cmd = "%s install -y" % (TDNF_PATH)
    was_changed = True
    if excludelist:
        cmd = "%s --exclude %s" % (cmd, ",".join(excludelist))
    if disable_gpg_check:
        cmd = "%s --nogpgcheck" % cmd
    if releasever:
        cmd = "%s --releasever %s" % (cmd, releasever)
    if conf_file:
        cmd = "%s -c %s" % (cmd, conf_file)
    if enablerepolist:
        for repo in enablerepolist:
            cmd = "%s --enablerepo=%s" % (cmd, repo)
    if disablerepolist:
        for repo in disablerepolist:
            cmd = "%s --disablerepo=%s" % (cmd, repo)
    cmd = "%s %s" % (cmd, packages)
    rc, stdout, stderr = module.run_command(cmd, check_rc=False)
    if rc != 0:
        module.fail_json(msg="failed to install %s" % (packages), stdout=stdout, stderr=stderr)
    if stderr.find('Nothing to do') >= 0:
        was_changed = False
    module.exit_json(changed=was_changed, msg="installed %s package(s)" % (packages), stdout=stdout, stderr=stderr)


def remove_packages(module, pkglist):
    packages = " ".join(pkglist)
    cmd = "%s remove -y %s" % (TDNF_PATH, packages)
    rc, stdout, stderr = module.run_command(cmd, check_rc=False)
    if rc != 0:
        module.fail_json(msg="failed to remove %s package(s)" % (packages), stdout=stdout, stderr=stderr)
    module.exit_json(changed=True, msg="removed %s package(s)" % (packages), stdout=stdout, stderr=stderr)

def convert_to_list(input_list):
    if input_list is None:
      input_list = []
    flat_list1 = [item for sublist in input_list for item in sublist if isinstance(sublist,list)]
    flat_list2 = [item for item in input_list if not isinstance(item,list)]
    return flat_list1 + flat_list2

# ==========================================
# Main control flow.


def main():
    module = AnsibleModule(
        argument_spec=dict(
            state=dict(default='present', choices=['present', 'installed', 'absent', 'removed', 'latest']),
            name=dict(type='list'),
            repository=dict(type='list'),
            update_cache=dict(default=False, type='bool'),
            upgrade=dict(default=False, type='bool'),
            enablerepo=dict(type='list', default=[]),
            disablerepo=dict(type='list', default=[]),
            disable_gpg_check=dict(type='bool', default=False),
            exclude=dict(type='list', default=[]),
            installroot=dict(type='str', default="/"),
            security_severity=dict(type='str', default=None),
            releasever=dict(default=None),
            conf_file=dict(type='str', default=None),
        ),
        required_one_of=[['name', 'update_cache', 'upgrade', 'security_severity']],
        mutually_exclusive=[['name', 'upgrade'], ['name', 'security_severity']],
        supports_check_mode=True
    )

    # Set LANG env since we parse stdout
    module.run_command_environ_update = dict(LANG='C', LC_ALL='C', LC_MESSAGES='C', LC_CTYPE='C')

    global TDNF_PATH
    TDNF_PATH = module.get_bin_path('tdnf', required=True)

    p = module.params

    pkglist = convert_to_list(p['name'])
    enablerepolist = convert_to_list(p['enablerepo'])
    disablerepolist = convert_to_list(p['disablerepo'])
    excludelist = convert_to_list(p['exclude'])

    # normalize the state parameter
    if p['state'] in ['present', 'installed', 'latest']:
        p['state'] = 'present'
    if p['state'] in ['absent', 'removed']:
        p['state'] = 'absent'

    if p['update_cache']:
        update_package_db(module, not p['name'] and not p['upgrade'] and not p['security_severity'])

    if p['upgrade']:
        upgrade_packages(
            module,
            excludelist,
            p['disable_gpg_check'],
            p['security_severity'],
            p['releasever'],
            p['conf_file'])

    if p['state'] in ['present', 'latest']:
        install_packages(
            module,
            pkglist,
            enablerepolist,
            disablerepolist,
            excludelist,
            p['disable_gpg_check'],
            p['installroot'],
            p['releasever'],
            p['conf_file'])
    elif p['state'] == 'absent':
        remove_packages(module, pkglist)

if __name__ == '__main__':
    main()