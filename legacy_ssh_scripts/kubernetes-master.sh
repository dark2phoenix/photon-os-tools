#!/bin/bash
set -eo xtrace

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

#
# Install kubernetes
#
#tdnf install kubernetes kubernetes-kubeadm -y

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

tdnf install kubeadm kubectl kubelet
systemctl enable --now kubelet

#
# Initialize the kubernetes cluster
#
kubeadm config images pull
kubeadm init --pod-network-cidr=10.244.0.0/16  | tee -a ~/kubernetes/kubeadm-init.log


#
# Create the admin user
#
useradd -m -G sudo -s /bin/bash kubeadm
echo -e "VMware1!\nVMware1!" | passwd kubeadm
cp /etc/kubernetes/admin.conf /home/kubeadm/
sudo chown $(id -u kubeadm):$(id -g kubeadm) /home/kubeadm/admin.conf
echo "export KUBECONFIG=/home/kubeadm/admin.conf" | tee -a /home/kubeadm/.bashrc

#
# Export kubeadm info for root because I'm too lazy to su
#
export KUBECONFIG=/etc/kubernetes/admin.conf
export KUBECONFIG=/etc/kubernetes/admin.conf | tee -a ~/.bashrc

#
# Install networking (I'm using calico, you can opt for something else)
#
wget -o ~/kubernetes/calico.yaml https://docs.projectcalico.org/v3.11/manifests/calico.yaml
sed -i 's+192.168.0.0/16+10.244.0.0/16+g' ~/kubernetes/calico.yaml 
kubectl apply -f ~/kubernetes/calico.yaml

#
# Start and enable the kube proxy (make it available on port 8080)
#
systemctl enable kube-proxy
systemctl start kube-proxy
