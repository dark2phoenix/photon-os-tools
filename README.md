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
```

The role only uses modules built into ansible-core, so no Ansible Galaxy collections are required. This only needs to be done once to ensure the successful usage of the playbook.

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

### Re-running on an existing host

The playbook is the starting configuration for a new Photon VM, and it is safe to re-run. Most settings (syslog forwarding, time sync, certificates, SSH keys, packages) are enforced on every run. Two files are only seeded, because something else often takes them over after the first boot:

| File | Written when | To overwrite it anyway |
| --- | --- | --- |
| `/etc/docker/daemon.json` | it doesn't exist yet | `force_reset_docker_config: true` |
| `/etc/systemd/scripts/ip4save` (the firewall) | it is still Photon's stock file, or the role's own file (first line `# Managed by Ansible (photon-os-tools)`) | `force_reset_firewall: true` |

When the role leaves one of them alone it says so in the play output and names the switch. Both switches are one-off: set them for the run that should reset the file, then remove them.

### Certificates

This task will put your trusted root certificate(s) into the default OS trust store.

### Docker

This task installs and configures the docker daemon. `docker_daemon_config` becomes `/etc/docker/daemon.json` (default: systemd cgroup driver, overlay2, json-file logs capped at 3 files of 10 MB per container), written only when the file doesn't exist yet; see above.

### Firewall

Photon restores `/etc/systemd/scripts/ip4save` at boot. When the role writes that file (see above) it starts from Photon's stock rules (drop inbound by default; allow loopback, established connections and SSH) and adds ping plus every entry in `firewall_allowed_ports` (default `22/tcp`, `80/tcp`, `443/tcp`; `port` or `port/proto`). It then reloads the firewall, and restarts Docker because reloading flushes Docker's own runtime rules.

### Logstash

This task sets up syslog forwarding from this VM to a syslog server. It was tested specifically against VMware Log Insight and VCF Operations for Logs.

syslog-ng reads the systemd journal directly (`system()`). Before 2026-11-09 the template read `/run/systemd/journal/syslog`, a socket Photon OS 5 never creates, so hosts forwarded only syslog-ng's own statistics line while the service showed active. After configuring, the role sends a `logger` test line and fails unless the remote destination's `written` counter rises, because a running service proves nothing.

- syslog_remote_server: [DNS name] :: Where to send logs. Use a name, not an IP, so moving the server doesn't silently break forwarding.
- syslog_remote_port: [514] :: Remote port.
- syslog_remote_transport: [tcp] :: `tcp` or `udp`.
- syslog_disk_buffer_bytes: [268435456] :: Disk buffer for the remote destination, so messages survive a server restart. `0` keeps the memory queue only.
- syslog_local_file: [/var/log/messages] :: Local copy. Empty means no local file.
- syslog_verify_delivery: [true] / syslog_verify_timeout: [15] :: The delivery check and how many seconds it waits.

The first start with the journal source reads the whole journal, so expect a one-off burst into the server and the local file.

### PIP

This task ensures that Python Pip gets installed with Ansible 3.  It has no configuration.

### Registry

Docker access to any defined insecure registries is configured through the `insecure-registries` key in `/etc/docker/daemon.json` (part of the Docker task).

- docker_insecure_registries: [List of `host:port` strings, or `{host, port}` entries] :: Private registries that you want this docker to be able to use.

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
