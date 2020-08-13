#!/bin/bash
#
# Ensure that we've got the master kubeadm-init.log before
# we start
#
if [ ! -f ~/kubernetes/kubeadm-init.log ]; then
    echo "Please copy the ~/kubernetes folder from the master to this"
    echo "user's home directory so the installation can begin"
    exit 1
fi
set -eo xtrace

#
# Install kubernetes
#
curl -o /etc/pki/rpm-gpg/GOOGLE-RPM-GPG-KEY https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
chmod 644 /etc/pki/rpm-gpg/GOOGLE-RPM-GPG-KEY
rpm --import /etc/pki/rpm-gpg/GOOGLE-RPM-GPG-KEY

cat > /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/GOOGLE-RPM-GPG-KEY
EOF

tdnf install kubeadm kubectl kubelet -y
systemctl enable --now kubelet

#
# Get the init string from kubeadm to get the join command
#
eval $(grep -A1 "kubeadm join.*$" ~/kubernetes/kubeadm-init.log | tr -d '\n' | tr -d '\\')