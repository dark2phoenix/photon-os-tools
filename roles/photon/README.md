# ansible-role-photon

Ansible playbook to automate basic setup of Photon OS instance.  This was designed to help in creating a basic VM with the settings that I use in the lab.

## Requirements

- Installation of VMware Photon 3.x, 4.x, or 5.x
- Prerequisites installed (if not called from launch_playbook.sh)
  - ansible 2.1 or higher
  - ansible-galaxy collection community.general
  - ansible-galaxy collection ansible.posix

## Role Variables

### Docker

|Parameter|Type|Default|Description|
|:------|:------|:-------|:-------|
|docker_photon_testing_in_docker|boolean|no|Sets up whether this is a native OS instance of Photon or a test instance in a Docker image (rare use case, should almost always be left to no)|
|docker_user_id|integer|unset| Unix id of the user to run docker as|
|docker_group_id|integer|995| Unix id of the group to run docker as|
|docker_daemon_config|yaml|see example|These are logging options for Docker.  They come directly from the [Docker Logging Documentation](https://docs.docker.com/config/containers/logging/configure/).  Declare here as YAML and it will be converted to JSON automatically in the config file|Array of URLs to setup to allow the use of Docker insecure registries.|
|docker_insecure_registries|array of string|unset|Array of additional insecure registries to configure docker with|

```yaml
docker_photon_testing_in_docker: yes|no
docker_user_id: 233
docker_gid: 995
docker_daemon_config:
  log-driver: "json-file"
  log-opts:
    max-size: "10m"
    max-file: "1000"
  storage-driver: "overlay2"
docker_insecure_registries: 
  - 'myregistry.domain.com:5000'
```

### Logstash

This task sets up syslog forwarding from this VM to a syslog server. It was tested specifically against VMware Log Insight.

|Parameter|Type|Default|Description|
|:------|:------|:-------|:-------|
|remote_syslog_server|string|unset|TCP/IP Address of the syslog server to forward logs to|
|remote_syslog_port|integer|514|TCP Port number of the remote syslog collector (typically 514)|
|local_syslog_file|string|'/var/log/messages'|Full path to local file to store syslog messages|

```yaml
remote_syslog_server: "172.16.14.25"
remote_syslog_port: 514
local_syslog_file: '/var/log/messages'
```

### tdnf

This tasks installs packages and configured tdnf repositories.

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

|Parameter|Type|Default|Description|
|:------|:------|:-------|:-------|
|photon_yum_repo|string|unset|HTTP address/IP of a specific custom Photon OS binary package repos.|
|photon_yum_repo_enabled|boolean|unset|Should the created repo be enabled|
|tdnf_updatecache|boolean|no|Instructs tdnf to update and rebuild the local cache of packages lists|
|tdnf_distrosync|boolean|no|Instruct tdnf to update all local patches to match the current distribution channel for the OS release|
|tdnf_additional_packages|[array of string]|unset|Ansible array of additional packages to install beyond the default packages (if you accidentally list of the defaults, will skip as it will already be installed)|

```yaml
photon_yum_repo: https://dl.bintray.com/vmware/photon_release_1.0_TP2_x86_64
photon_yum_repo_enabled: yes|no
tdnf_updatecache: yes|no
tdnf_distrosync: yes|no
tdnf_additional_packages:
    - unzip
```

### Timesync

This section allows you to configure NTP and time zone related settings.

|Parameter|Type|Default|Description|
|:------|:------|:-------|:-------|
|ntp_timezone|string|unset| Unix [standard time zone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)|
|ntp_servers|array of strings|\[0-3\].pool.ntp.org|List of primary NTP Server TCP/IP addresses to use for time synch|
|ntp_fallback_servers|array of Strings|\[0-3\].pool.ntp.org|List of secondary/fallback NTP Server TCP/IP addresses to use if all primary sources are unusable|

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

|Parameter|Type|Default|Description|
|:------|:------|:-------|:-------|
|ssl_root_certificate_pem|string|unset| This contains the contents of the root certificates to be trusted by this OS instance in PEM format.  It should include all applicable roots and intermediate certificates with no spaces or blank lines between them|
|ssl_root_certificate_pem_filename|string|unset|Name of the compiled root certificate that will be added to the OS default trust store|

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

|Parameter|Type|Default|Description|
|:------|:------|:-------|:-------|
|users_root_pwd_no_expire|boolean|no|Sets the root user password to never expire which is _NOT RECOMMENDED FOR PRODUCTION!!_|
|ssh_enabled_users|array of name and ssh_key strings |unset|list of users and ssh_keys to enable|
| - name|string|unset| name of the user
| - ssh_key|string|unset|SSH access key entry in the same format found in the user's ~/.ssh/authorized_keys file|

```yaml
 ssh_enabled_users:
  - name: root
    ssh_key: "ssh-rsa AAAA... a-private-key"
users_root_pwd_no_expire: yes 
```

### PIP

This task ensures that Python Pip gets installed with Ansible 3.  It has no configuration.

### IP Tables

This task contains sets up some basic firewall rules for use with the VM:

- Allow loopback traffic
- Allow Allow established connections
- Allow ICMP (ping) to and from the OS
- Allow Port 80 (HTTP) into the VM
- Allow Port 443 (HTTPS) into the VM
- Allow Port 22 (ssh) into the VM

These tasks are not currently configurable - comment out any tasks you do not want to run.

## Example playbook

See the included 'configure-photon-sample.yaml' for a full example.

## License and Copyright

Copyright 2015 VMware, Inc.  All rights reserved.
SPDX-License-Identifier: Apache-2.0 OR GPL-3.0-only
This code is Dual Licensed Apache-2.0 or GPLv3

## Author Information

This role was originally created in 2015 by [Tom Hite / VMware](http://www.vmware.com/).

Shamlessly co-opted and expanded by [Christopher McCann](dark3phoenix@gmail.com).
