#!/bin/bash
set -eo xtrace

#
# Install useful packages
#
tdnf install vim wget tar traceroute -y

#
# Create a working folder for commands both master and node
# scripts will use
#
mkdir -p ~/kubernetes

#
# iptables firewall rules for kubernetes master
#
# ping
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
# etcd
iptables -A INPUT -p tcp -m tcp --dport 2379:2380 -j ACCEPT
# kubernetes
iptables -A INPUT -p tcp -m tcp --dport 6443 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 8080 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 10250:10252 -j ACCEPT
# calico
iptables -A INPUT -p tcp -m tcp --dport 179 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 4789 -j ACCEPT
# save rules
iptables-save > /etc/systemd/scripts/ip4save

#
# Enable IP forwarding on the kernel
#
cat > /etc/sysctl.d/kubernetes.conf << "EOF"
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

#
#  Change docker over to cgroup
# 
tdnf install docker -y
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

systemctl daemon-reload
systemctl restart docker
