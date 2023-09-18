# photon-os-tools

## History

Building a small tool kit for common configuration tasks in Photon.

This is mostly a learning excercise for me to get comfortable with Ansible.  I started with the photon project that was developed from the [Ansible Photon Role](https://github.com/vmware-archive/ansible-role-photon.git) Tom Hite started at VMware and have updated it and expanded its functionality to suit my needs.

## Requirements

This role was designed and tested for [VMware Photon OS Version 3 and Version 4](https://vmware.github.io/photon/assets/files/html/3.0/Introduction.html).

For this role to work properly, of course, Python 3.x and Ansible must be installed into the Photon VM.

The following commands should be executed on the OS to sure all the prequisite packages are installed:

```
tdnf install ansible -y
ansible-galaxy collection install community.general
ansible-galaxy collection install ansible.posix
```

This only needs to be done once to ensure the successful usage of the playbook

## Using the playbook

### One time simple usage

1.  Create a configure-photon.yaml file using the configure-photon-sample.yaml as a guide and save it to root directory of this project.
2.  Execute launch_playbook.sh which will install the prequisites as well execute the role using the data in the configure-photon.yaml

### Integrating into a larger Anslbile Solution

1. Add the needed facts (see configure-photon-sample.yaml) to your Ansible execution system
2. Add the Rolle files to your roles distribution system
2. Call the Photon Role


## Tasks in this Playbook

### Certificates

This task will put your trusted root certificate(s) into the default OS trust store.

#### Parameters
<dl>
<dt>ssl_root_certicate_pem: [cert contents]</dt>
<dd>This contains the contents of the root certificates to be trusted by this OS instance.  I should include all applicable roots and itermediate certificates with no spaces or blank lines bsween them.</dd>
<dt>ssl_root_certificate_pem_filename:  [string]</dt>
<dd>Name of the compiled root certificate that will be added to the OS default trust store.
</dd>
</dl>

#### Sample YAML
```
ssl_root_certificate_pem: |
-----BEGIN CERTIFICATE-----
intermediate certificate (if required)
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
root certificate
-----END CERTIFICATE-----
ssl_root_certificate_pem_filename: home_mccannical_net_root.pem
```
### Docker

This module configures the docker daemon.

#### Parameters
<dl>
<dt>docker_photon_testing_in_docker: [yes/no]</dt>
<dd>Sets up whether this is a native OS instance of Photon or a test instance in a Docker image (rare use case, should almost always be left to no)</dd>
<dt>docker_user_id: [integer]</dt>
<dd>UNIX id of the user to run docker as</dd>
<dt>docker_group_id: [integer]</dt>
<dd>UNIX id of the group to run docker as</dd>
<dt>docker_daemon_config: [various sub options]</dt>
<dd>These are logging options for Docker.  They come directly from the [Docker Logging Documentation](https://docs.docker.com/config/containers/logging/configure/)</dd>
</dl>

#### Sample YAML
```
docker_photon_testing_in_docker: no
docker_user_id: 233
docker_group_id: 233
docker_insecure_registries: []
docker_daemon_config:
  log-driver: "json-file"
  log-opts:
  max-size: "10m"
  max-file: "1000"
```
### IPTables

This task contains sets up some basic firewall rules for use with the VM:

* Allow loopback traffic
* Allow Allow established connections
* Allow ICMP (ping) to and from the OS
* Allow Port 80 (HTTP) into the VM
* Allow Port 443 (HTTPS) into the VM
* Allow Port 22 (ssh) into the VM

These tasks are not currently configurable - comment out any tasks you do not want to run.

### Logstach

This task sets up syslog forwarding from this VM to a syslog server. It was tested specficially against VMware Log Insight.

#### Parameters

<dl>
<dd>syslog_remote_server: [TCP/IP Addresss of syslog server]</dd>
<dt>TCP/IP Address of the syslog server to foward logs to</dt>
<dd>syslog_remote_port: [integer]</dd>
<dt>TCP Port nunber of the remote syslog collector (typically 514)</dt>
</dl>

### PIP

This task ensures that Python Pip gets installed with Ansible 3.  It has no configuration.

### Registry

This Task sets up access for Docker to any defined insecure registries.
<dl>
<dt>docker_insecure_registries: [Comma separated list of URL's to the Repositories]</dt>
<dd>List of any private registry URL's that you want this docker to be able to use.</dd>
</dl>

### TDNF

This task allows for the configuration of local tdnf settings as well as installing/updating packages to provide a "normal" level of admin tooling:  sudo, bindutils, openssl-c_rehash, ansible, vim, vim-extra, iputils, nfs-utils, logrotate, wget, ntp, tzdata, traceroute, and tar.

#### Parameters

<dl>
<dd>tdnf_updatecache: [yes/no]</dd>
<dt>Instructs tdnf to update and rebuild the local cache of packages lists</dt>
<dd>tdnf_distrosync: [yes/no]</dd>
<dt>Instruct tdnf to update all local patches to match the current distrubution channel for the OS release</dt>
<dd> tdnf_additional_packages: [array of string]</dd>
Ansible array of additional packages to install beyond the default packages (if you accidentally list of the defaults, will skip as it will already be installed)
</dl>
 
 #### Sample YAML

```
tdnf_updatecache: no
tdnf_distrosync: no
tdnf_additional_packages:
  - package1
  - package2
  - package3
 ```           

### Timesync

This task sets up proper NTP time for the OS using systemd-timesync.

#### Parameters

<dl>
<dd>ntp_timezone: [string]</dd>
<dt>Unix [standard time zone.  See: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)</dt>
<dd>ntp_servers: [array of strings]</dd>
<dt>List of primary NTP Server TCP/IP addresses to use for time synch.</dt>
<dd>ntp_fallback_servers</dd>
<dt>List of secondary/fallyback NTP Server TCP/IP addresses to use if all primary sources are unusable</dt>
</dl>

#### Example YAML
```
ntp_timezone: "America/New_York"
ntp_servers:
  - 172.28.5.2
  - 172.28.5.3
  - 172.28.6.2
  - 172.28.6.3
ntp_fallback_servers:
  - 0.pool.ntp.org
  - 1.pool.ntp.org
  - 2.pool.ntp.org
  - 3.pool.ntp.org
```

### Users

This task sets up some initial configuration for users in the OS. 


#### Parameters
<dl>
<dt>users_root_pwd_no_expire: [yes/no]</dt>
<dd>Sets the root user password to never expire which is <u>NOT RECOMMENTED FOR PRODUCTION!!</u></dd>
<dt>ssh_enabled_users:<dt>
<dt>&nbsp;&nbsp;name [string]</dt>
<dd> Name of the user to set an ssh access key</dd> 
<dt>&nbsp;&nbsp;ssh_key [RSA ssh keystring]</dt>
<dd>SSH access key entry in the same format found in the user's ~/.ssh/authorized_keys file</dd>
</dl>

#### Sample YAML
```
users_root_pwd_no_expire:
ssh_enabled_users:
  - name: root
    ssh_key: "[ssh-key data example:  ssh rsa AAaaa.....=keyname]"
```


