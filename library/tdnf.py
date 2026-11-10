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

def nothing_to_do(stdout, stderr):
    return 'Nothing to do' in (stdout or '') or 'Nothing to do' in (stderr or '')


def is_installed(module, name):
    """True if an installed package provides name (works for package names and provides)."""
    rc, _, _ = module.run_command([RPM_PATH, '-q', '--whatprovides', name], check_rc=False)
    return rc == 0


def common_options(excludelist, disable_gpg_check, releasever, conf_file,
                   enablerepolist=None, disablerepolist=None, security_severity=None):
    opts = []
    if excludelist:
        opts += ['--exclude', ','.join(excludelist)]
    if disable_gpg_check:
        opts.append('--nogpgcheck')
    if security_severity:
        opts += ['--sec-severity', security_severity]
    if releasever:
        opts += ['--releasever', str(releasever)]
    if conf_file:
        opts += ['-c', conf_file]
    for repo in enablerepolist or []:
        opts.append('--enablerepo=%s' % repo)
    for repo in disablerepolist or []:
        opts.append('--disablerepo=%s' % repo)
    return opts


def update_package_db(module, exit):
    # Refreshing metadata changes nothing on the system, but check mode
    # promises no commands with side effects, so it is skipped there.
    if module.check_mode:
        if exit:
            module.exit_json(changed=False, msg='check mode: package db not refreshed')
        return False
    rc, stdout, stderr = module.run_command([TDNF_PATH, 'makecache'], check_rc=False)
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
    opts = common_options(excludelist, disable_gpg_check, releasever, conf_file,
                          security_severity=security_severity)
    if module.check_mode:
        # --assumeno resolves the transaction and then declines it
        rc, stdout, stderr = module.run_command([TDNF_PATH, 'upgrade', '--assumeno'] + opts, check_rc=False)
        changed = not nothing_to_do(stdout, stderr)
        module.exit_json(changed=changed, msg='check mode: packages would be upgraded' if changed else 'check mode: already at latest',
                         stdout=stdout, stderr=stderr)
    rc, stdout, stderr = module.run_command([TDNF_PATH, 'upgrade', '-y'] + opts, check_rc=False)
    if rc != 0:
        module.fail_json(msg="failed to upgrade packages", stdout=stdout, stderr=stderr)
    if nothing_to_do(stdout, stderr):
        module.exit_json(changed=False, msg="packages already at latest", stdout=stdout, stderr=stderr)
    module.exit_json(changed=True, msg="packages upgraded", stdout=stdout, stderr=stderr)


def install_packages(
            module,
            pkglist,
            state,
            enablerepolist,
            disablerepolist,
            excludelist,
            disable_gpg_check,
            installroot,
            releasever,
            conf_file):
    """state 'present' installs only missing packages and never upgrades an
    installed one; state 'latest' installs missing packages and upgrades the
    rest (tdnf install upgrades an installed package when a newer one exists)."""
    opts = common_options(excludelist, disable_gpg_check, releasever, conf_file,
                          enablerepolist, disablerepolist)
    if state == 'present':
        targets = [name for name in pkglist if not is_installed(module, name)]
        if not targets:
            module.exit_json(changed=False, msg="%s already installed" % " ".join(pkglist))
    else:
        targets = list(pkglist)

    if module.check_mode:
        if state == 'present':
            module.exit_json(changed=True, msg="check mode: would install %s" % " ".join(targets))
        rc, stdout, stderr = module.run_command([TDNF_PATH, 'install', '--assumeno'] + opts + targets, check_rc=False)
        changed = not nothing_to_do(stdout, stderr)
        module.exit_json(changed=changed,
                         msg=("check mode: would install or upgrade %s" if changed else "check mode: %s already at latest") % " ".join(targets),
                         stdout=stdout, stderr=stderr)

    rc, stdout, stderr = module.run_command([TDNF_PATH, 'install', '-y'] + opts + targets, check_rc=False)
    if rc != 0:
        module.fail_json(msg="failed to install %s" % " ".join(targets), stdout=stdout, stderr=stderr)
    if nothing_to_do(stdout, stderr):
        module.exit_json(changed=False, msg="%s already at latest" % " ".join(targets), stdout=stdout, stderr=stderr)
    module.exit_json(changed=True, msg="installed or upgraded %s" % " ".join(targets), stdout=stdout, stderr=stderr)


def remove_packages(module, pkglist):
    targets = [name for name in pkglist if is_installed(module, name)]
    if not targets:
        module.exit_json(changed=False, msg="%s not installed" % " ".join(pkglist))
    if module.check_mode:
        module.exit_json(changed=True, msg="check mode: would remove %s" % " ".join(targets))
    rc, stdout, stderr = module.run_command([TDNF_PATH, 'remove', '-y'] + targets, check_rc=False)
    if rc != 0:
        module.fail_json(msg="failed to remove %s package(s)" % " ".join(targets), stdout=stdout, stderr=stderr)
    module.exit_json(changed=True, msg="removed %s package(s)" % " ".join(targets), stdout=stdout, stderr=stderr)

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

    global TDNF_PATH, RPM_PATH
    TDNF_PATH = module.get_bin_path('tdnf', required=True)
    RPM_PATH = module.get_bin_path('rpm', required=True)

    p = module.params

    pkglist = convert_to_list(p['name'])
    enablerepolist = convert_to_list(p['enablerepo'])
    disablerepolist = convert_to_list(p['disablerepo'])
    excludelist = convert_to_list(p['exclude'])

    # normalize the state parameter ('latest' stays distinct: it upgrades)
    if p['state'] == 'installed':
        p['state'] = 'present'
    if p['state'] == 'removed':
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
            p['state'],
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