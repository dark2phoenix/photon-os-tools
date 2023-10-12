# photon-os-tools

## History

Building a small tool kit for common configuration tasks in Photon.

This is mostly a learning exercise for me to get comfortable with Ansible.  I started with the photon project that was developed from the [Ansible Photon Role](https://github.com/vmware-archive/ansible-role-photon.git) Tom Hite started at VMware and have updated it and expanded its functionality to suit my needs.

## Requirements

This role was designed and tested for [VMware Photon OS Version 3, Version 4 and Version 5](https://vmware.github.io/photon/docs-v5/).

For this role to work properly, of course, Python 3.x and Ansible must be installed into the Photon VM.

The following commands should be executed on the OS to sure all the prerequisite packages are installed:

``` shell
tdnf install ansible -y
ansible-galaxy collection install community.general
ansible-galaxy collection install ansible.posix
```

This only needs to be done once to ensure the successful usage of the playbook.

The included launch_playbook.sh will run these commands before executing the playbook.

## Using the playbook

### One time simple usage

1. Create a configure-photon.yaml file using the configure-photon-sample.yaml as a guide and save it to root directory of this project.
2. Execute launch_playbook.sh which will install the prerequisites as well execute the role using the data in the configure-photon.yaml

### Integrating into a larger Ansible Solution

1. Add the needed facts (see configure-photon-sample.yaml) to your Ansible execution system
2. Add the Role files to your roles distribution system
3. Call the Photon Role

## Tasks in this Playbook

### Certificates

This task will put your trusted root certificate(s) into the default OS trust store.

### Docker

This module configures the docker daemon.

### IP Tables

This task contains sets up some basic firewall rules for use with the VM:

- Allow loopback traffic
- Allow Allow established connections
- Allow ICMP (ping) to and from the OS
- Allow Port 80 (HTTP) into the VM
- Allow Port 443 (HTTPS) into the VM
- Allow Port 22 (ssh) into the VM

These tasks are not currently configurable - comment out any tasks you do not want to run.

### Logstash

This task sets up syslog forwarding from this VM to a syslog server. It was tested specifically against VMware Log Insight.

### PIP

This task ensures that Python Pip gets installed with Ansible 3.  It has no configuration.

### Registry

This Task sets up access for Docker to any defined insecure registries.

- docker_insecure_registries: [Comma separated list of URL's to the Repositories] :: List of any private registry URL's that you want this docker to be able to use.

### tdnf

This task allows for the configuration of local tdnf settings as well as installing/updating packages to provide a "normal" level of admin tooling:  

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

### Timesync

This task sets up proper NTP time for the OS using systemd-timesync and set the timezone

### Users

This task sets up some initial configuration for users in the OS including setting up ssh keys for users and enabling the root user

Detailed documentation about the photon role can be found in the Role [README](/roles/photon/README.md)