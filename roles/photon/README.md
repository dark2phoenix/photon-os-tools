# ansible-role-photon

Ansible playbook to automate basic setup of Photon OS instance.  This was designed to help in creating a basic VM with the settings that I use in the lab.

## Requirements

- Installation of VMware Photon 3.x, 4.x, or 5.x
- Prerequisites installed (if not called from launch_playbook.sh)
    - ansible-core 2.15 or higher (only `ansible.builtin` modules are used; no Galaxy collections needed)

## Role Variables

### Docker

**Table:** Docker Configurable Parameters

| Parameter                          | Type    | Default     | Description                                                                                                                                                                                                                                            |
| :--------------------------------- | :------ | :---------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| docker_testing_of_photon_in_docker | boolean | no          | Sets up whether this is a native OS instance of Photon or a test instance in a Docker image (rare use case, should almost always be left to no)                                                                                                        |
| docker_user_id                     | integer | 233         | Unix id of the user to run docker as                                                                                                                                                                                                                   |
| docker_group_id                    | integer | 995         | Unix id of the group to run docker as                                                                                                                                                                                                                  |
| docker_daemon_config               | yaml    | see example | Contents of `/etc/docker/daemon.json`, declared as YAML and converted to JSON (options from the [Docker daemon documentation](https://docs.docker.com/reference/cli/dockerd/#daemon-configuration-file)). Written only when the file doesn't exist yet |
| force_reset_docker_config          | boolean | false       | Replace an existing `/etc/docker/daemon.json` with `docker_daemon_config`                                                                                                                                                                              |
| docker_insecure_registries         | array   | []          | Additional insecure registries, written to `insecure-registries` in daemon.json. Entries may be `'host:port'` strings or `{host: ..., port: ...}` mappings                                                                                             |

**Example:**  docker

```yaml
docker_testing_of_photon_in_docker: yes|no
docker_user_id: 233
docker_group_id: 995
docker_daemon_config:
  exec-opts:
    - "native.cgroupdriver=systemd"
  log-driver: "json-file"
  log-opts:
    max-size: "10m"
    max-file: "3"
  storage-driver: "overlay2"
docker_insecure_registries: 
  - 'myregistry.domain.com:5000'
```

### Firewall

**Table:** Firewall Configurable Parameters

| Parameter              | Type    | Default                       | Description                                                                     |
| :--------------------- | :------ | :---------------------------- | :------------------------------------------------------------------------------ |
| firewall_allowed_ports | array   | `22/tcp`, `80/tcp`, `443/tcp` | Inbound ports opened in `/etc/systemd/scripts/ip4save` (`port` or `port/proto`) |
| force_reset_firewall   | boolean | false                         | Replace a locally changed `ip4save` with the role's firewall                    |

The role writes `ip4save` only when it is Photon's stock file, the role's own file, or `force_reset_firewall` is set; otherwise it reports that the file was left unchanged.

### Logstash/Syslog

This task sets up syslog forwarding from this VM to a syslog server. It was tested specifically against VMware Log Insight and VCF Operations for Logs. syslog-ng reads the systemd journal directly, and after configuring the role sends a test line and fails unless the server received it.

**Table:** Logstash Configurable Parameters

| Parameter                | Type    | Default           | Description                                                                                                   |
| :----------------------- | :------ | :---------------- | :------------------------------------------------------------------------------------------------------------ |
| syslog_remote_server     | string  | unset             | DNS name of the syslog server. Use a name, not an IP, so moving the server doesn't silently break forwarding  |
| syslog_remote_port       | integer | 514               | Remote port                                                                                                   |
| syslog_remote_transport  | string  | tcp               | `tcp` or `udp`                                                                                                |
| syslog_disk_buffer_bytes | integer | 268435456         | Disk buffer for the remote destination, so messages survive a server restart. `0` keeps the memory queue only |
| syslog_local_file        | string  | /var/log/messages | Local copy. Empty means no local file                                                                         |
| syslog_verify_delivery   | boolean | true              | Send a test line and fail unless the remote destination's `written` counter rises                             |
| syslog_verify_timeout    | integer | 15                | Seconds the delivery check waits                                                                              |

**Example:** Logstash/Syslog Configurable Parameters

```yaml
syslog_remote_server: "logs.example.com"
syslog_remote_port: 514
syslog_remote_transport: tcp
syslog_local_file: /var/log/messages
```

### tdnf

This tasks installs packages and configured tdnf repositories.

Playbook will install the following packages by default:

- `sudo`
- `bindutils`
- `openssl-c_rehash`
- `ansible`
- `vim`
- `vim-extra`
- `iputils`
- `nfs-utils`
- `logrotate`
- `wget`
- `ntp`
- `tzdata`
- `traceroute`
- `tar`

**Table:** tdnf Configurable Parameters

| Parameter                  | Type                | Default | Description                                                                                                                                                       |
| :------------------------- | :------------------ | :------ | :---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `photon_yum_repo`          | string              | unset   | HTTP address/IP of a specific custom Photon OS binary package repos.                                                                                              |
| `photon_yum_repo_enabled`  | boolean             | unset   | Should the created repo be enabled                                                                                                                                |
| `tdnf_updatecache`         | boolean             | no      | Instructs tdnf to update and rebuild the local cache of packages lists                                                                                            |
| `tdnf_distrosync`          | boolean             | no      | Instruct tdnf to update all local patches to match the current distribution channel for the OS release                                                            |
| `tdnf_additional_packages` | \[array of string\] | unset   | Ansible array of additional packages to install beyond the default packages (if you accidentally list of the defaults, will skip as it will already be installed) |

**Example:** tdnf

```yaml
photon_yum_repo: https://dl.bintray.com/vmware/photon_release_1.0_TP2_x86_64
photon_yum_repo_enabled: yes|no
tdnf_updatecache: yes|no
tdnf_distrosync: yes|no
tdnf_additional_packages:
    - unzip
```

### TimeSync

This section allows you to configure NTP and time zone related settings.

**Table:** TimeSync Configurable Parameters

| Parameter            | Type             | Default              | Description                                                                                       |
| :------------------- | :--------------- | :------------------- | :------------------------------------------------------------------------------------------------ |
| ntp_timezone         | string           | unset                | Unix [standard time zone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)           |
| ntp_servers          | array of strings | \[0-3\].pool.ntp.org | List of primary NTP Server TCP/IP addresses to use for time synch                                 |
| ntp_fallback_servers | array of Strings | \[0-3\].pool.ntp.org | List of secondary/fallback NTP Server TCP/IP addresses to use if all primary sources are unusable |

**Example:** tdnf

```yaml
ntp_timezone: "Etc/UTC"
ntp_servers:
  - 0.pool.ntp.org
  - 1.pool.ntp.org
  - 2.pool.ntp.org
  - 3.pool.ntp.org
ntp_fallback_servers:
  - 4.pool.ntp.org
  - 5.pool.ntp.org
  - 6.pool.ntp.org
  - 7.pool.ntp.org
```

### SSL Certificates

Add custom root and intermediate certificates to the default OS store

**Table:** SSL Certificates Configurable Parameters

| Parameter                         | Type   | Default | Description                                                                                                                                                                                                           |
| :-------------------------------- | :----- | :------ | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ssl_root_certificate_pem          | string | unset   | This contains the contents of the root certificates to be trusted by this OS instance in PEM format.  It should include all applicable roots and intermediate certificates with no spaces or blank lines between them |
| ssl_root_certificate_pem_filename | string | unset   | Name of the compiled root certificate that will be added to the OS default trust store                                                                                                                                |

**Example:** SSL certificates

```yaml
ssl_root_certificate_pem: |
    -----BEGIN CERTIFICATE-----
    intermediate certificate (if required)
    -----END CERTIFICATE-----
    -----BEGIN CERTIFICATE-----
    root certificate
    -----END CERTIFICATE-----
 ssl_root_certificate_pem_filename: my_custom_root.pem
```

### Users

Set ssh access keys for a list of users

**Table:** Users Configurable Parameters

| Parameter                     | Type                              | Default | Description                                                                             |
| :---------------------------- | :-------------------------------- | :------ | :-------------------------------------------------------------------------------------- |
| users_root_pwd_no_expire      | boolean                           | no      | Sets the root user password to never expire which is _NOT RECOMMENDED FOR PRODUCTION!!_ |
| ssh_enabled_users             | array of name and ssh_key strings | unset   | list of users and ssh_keys to enable                                                    |
| `ssh_enabled_users[].name`    | string                            | unset   | name of the user                                                                        |
| `ssh_enabled_users[].ssh_key` | string                            | unset   | SSH access key entry in the same format found in the user's ~/.ssh/authorized_keys file |

**Example:** users

```yaml
ssh_enabled_users:
  - name: root
    ssh_key: "ssh-rsa AAAA... a-private-key"
users_root_pwd_no_expire: yes
```

### PIP

This task ensures that Python Pip gets installed with Ansible 3.  It has no configuration.

## Example playbook

See the included 'configure-photon-sample.yaml' for a full example.

## License and Copyright

Copyright 2015 VMware, Inc.  All rights reserved.
SPDX-License-Identifier: Apache-2.0 OR GPL-3.0-only
This code is Dual Licensed Apache-2.0 or GPLv3

## Author Information

This role was originally created in 2015 by [Tom Hite / VMware](http://www.vmware.com/).

Shamelessly co-opted and expanded by [Christopher McCann](mailto:dark3phoenix@gmail.com).
