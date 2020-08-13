#!/bin/bash
#
#
# iptables firewall rules for kubernetes node
#
# ping
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
 
# kubernetes
iptables -A INPUT -p tcp -m tcp --dport 10250:10252 -j ACCEPT
 
# workloads
iptables -A INPUT -p tcp -m tcp --dport 30000:32767 -j ACCEPT
 
# calico
iptables -A INPUT -p tcp -m tcp --dport 179 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 4789 -j ACCEPT
 
# save rules
iptables-save > /etc/systemd/scripts/ip4save


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