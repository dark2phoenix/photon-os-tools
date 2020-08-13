#!/bin/bash
set -eo xtrace

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

tdnf install kubeadm kubectl kubelet -y
systemctl enable --now kubelet

#
# Initialize the kubernetes cluster
#
kubeadm config images pull
kubeadm init --pod-network-cidr=10.244.0.0/16 | tee ~/kubernetes/kubeadm-init.log

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
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> /root/.bashrc
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> /root/.bash_profile

#
# Install networking (I'm using calico, you can opt for something else)
#
wget -O ~/kubernetes/calico.yaml https://docs.projectcalico.org/v3.11/manifests/calico.yaml
sed -i 's+192.168.0.0/16+10.244.0.0/16+g' ~/kubernetes/calico.yaml 
kubectl apply -f ~/kubernetes/calico.yaml