#!/bin/bash
set -o xtrace


tdnf install ansible -y
ansible-galaxy collection install community.general
ansible-galaxy collection install ansible.posix
ansible-playbook --connection=local --inventory 127.0.0.1 configure-photon.yml