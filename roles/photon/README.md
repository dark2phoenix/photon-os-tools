# ansible-role-photon

Ansible playbook to automate basic setup of Photon OS instance.  This was designed to help in creating a basic VM with the settings that I use in the lab.

## Requirements

One instance of Photon OS running

## Role Variables

### Docker Information

#### Testing photon inside docker

Rare use case, but if you were running this inside a docker container, then set this to yes to setup docker accordingly

```yaml
docker_photon_testing_in_docker: yes|no
```

#### Docker User and Group Id's

The docker user and group id's to set (gets created if missing) for socket access and similar.

```yaml
    docker_user_id: 233
    docker_gid: 995
```

#### Insecure Registries

Array of URLs to setup to allow the use of Docker insecure registries.

```yaml
docker_insecure_registries: ['myregistry.domain.com:5000']
```

#### Daemon config

Daemon config in YAML format.  Will be converted to JSON for the actual file

```yaml
docker_daemon_config:
    exec-opts:
    - "native.cgroupdriver=systemd"
    log-driver: "json-file"
    log-opts:
    max-size: "10m"
    max-file: "1000"
    storage-driver: "overlay2"
#    storage-opts:
#    - "overlay2.override_kernel_check=true"
```

### Syslog Information

#### Syslog Server

Set these two items to log to setup for logging to a remote syslog server.
Note:  This assumes the use of logstash named variables, so if using
a role that includes those by default, you'd need not set them in your play.

```yaml
remote_syslog_server: "172.16.14.25"
remote_syslog_port: 514
```

#### Local Syslog Location

Set path to log locally, if unset, the resulting setup won't log to a file

```yaml
local_syslog_file: '/var/log/messages'
```

### tdnf

Playbook will install the following packages by default:

- sudo
- bindutils
- openssl-c_rehash
- ansible
- vim
- vim-extra
- iputils
- nfs-utils
- logrotate
- wget
- ntp
- tzdata
- traceroute
- tar

#### Custom repository

Set these to utilize specific Photon OS binary package repos.

```yaml
photon_yum_repo: https://dl.bintray.com/vmware/photon_release_1.0_TP2_x86_64
photon_yum_repo_enabled: yes|no
```

#### Repository cache

Enable to update the repository caches

```yaml
tdnf_updatecache: yes|no
```

#### Distrosync

Synchronize installed packages to the latest available versions

```yaml
tdnf_distrosync: yes|no
```

#### Additional packages

Install any additional packages

```yaml
tdnf_additional_packages:
    - unzip
```

### NTP

This section allows you to configure NTP and timzezone settings

#### Timezone

Use the timezone identifier as defined in [tzdata](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)

```yaml
ntp_timezone: "Etc/UTC"
```

#### NTP servers

List of NTP Servers to synch with

```yaml
ntp_servers:
  - 0.pool.ntp.org
  - 1.pool.ntp.org
  - 2.pool.ntp.org
  - 3.pool.ntp.org
```

#### NTP fallback servers

List of NTP Fallback servers to synch with

```yaml
ntp_fallback_servers:
  - 4.pool.ntp.org
  - 5.pool.ntp.org
  - 6.pool.ntp.org
  - 7.pool.ntp.org
```

### SSL Certificates

Add custom root and intermediate certificates to the default OS store

#### Root/Intermediate Certs

Add root or intermediate certificates in PEM format

```yaml
ssl_root_certificate_pem: |
    -----BEGIN CERTIFICATE-----
    intermediate certificate (if required)
    -----END CERTIFICATE-----
    -----BEGIN CERTIFICATE-----
    root certificate
    -----END CERTIFICATE-----
```

#### Name custom PEM certificate

Name for the custom perm certificate

```yaml
 ssl_root_certificate_pem_filename: my_custom_root.pem    
```

### SSH keys for Users

Set ssh access keys for a list of users

#### ssh private key

```yaml
 ssh_enabled_users:
              - name: root
                ssh_key: "ssh-rsa AAAA... a-private-key"
```

#### non-expiring root password

Set the root account's password to not expire (not recommended outside controlled lab environments)

```yaml
users_root_pwd_no_expire: yes 
```

## Example playbook

See the included 'configure-photon-sample.yaml' for a full example.

## License and Copyright

Copyright 2015 VMware, Inc.  All rights reserved.
SPDX-License-Identifier: Apache-2.0 OR GPL-3.0-only
This code is Dual Licensed Apache-2.0 or GPLv3

## Author Information

This role was originally created in 2015 by [Tom Hite / VMware](http://www.vmware.com/).

Shamlessly co-opted and expanded by [Christopher McCann](dark3phoenix@gmail.com).
