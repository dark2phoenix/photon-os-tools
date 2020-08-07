#!/bin/bash
set -o xtrace


tdnf install ansible -y
ansible-playbook --connection=local --inventory 127.0.0.1 configure-photon.yml