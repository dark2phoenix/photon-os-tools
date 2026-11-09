#!/bin/bash
set -o xtrace

tdnf install ansible -y
ansible-playbook --connection=local configure-photon.yml