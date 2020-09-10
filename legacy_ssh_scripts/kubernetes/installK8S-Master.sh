#!/bin/bash
set -eo xtrace

#
# Set Defaults
#
ADMIN_USER='kubeadmin'
ADMIN_PASSWORD='VMware1!'
PRIVATE_NETWORK='10.244.0.0/16'

valid_cidr_network() {
  local ip="${1%/*}"    # strip bits to leave ip address
  local bits="${1#*/}"  # strip ip address to leave bits
  local IFS=.; local -a a=($ip)

  # Sanity checks (only simple regexes)
  [[ $ip =~ ^[0-9]+(\.[0-9]+){3}$ ]] || return 1
  [[ $bits =~ ^[0-9]+$ ]] || return 1
  [[ $bits -gt 32 ]] || return 1

  # Create an array of 8-digit binary numbers from 0 to 255
  local -a binary=({0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1}{0..1})
  local binip=""

  # Test and append values of quads
  for quad in {0..3}; do
    [[ "${a[$quad]}" -gt 255 ]] && return 1
    printf -v binip '%s%s' "$binip" "${binary[${a[$quad]}]}"
  done

  # Fail if any bits are set in the host portion
  [[ ${binip:$bits} = *1* ]] && return 1

  return 0
}

#
# Show help
#
show_help() {
  cat << EOF
usage: captureLogLoop [--admin-user {username}] [--admin-password {password}][-?|-h|--help]
  options:
    --admin-user {username}           Local admin user to create for proper control of kubernetes
    --admin-password {password}       Password for the local admin user
    --private-network {address/cidr}  The internal network for use by Kubernetes (e.g. 10.244.0.0/16)
    -?, -h, --help                     Show this help
EOF
  exit 0
}

#
# Process Command line Arguments
#

for arg in "$@"
do
    case $arg in
        --admin-user)
          ADMIN_USER="$2"
          ADMIN_USER=`echo "$ADMIN_USER" | tr -d '"\047,\\\/'`
          echo "Admin User:  $ADMIN_USER"
          if [[ ! "$ADMIN_USER" ]]; then 
            echo "$1 should be called with a value"
            exit 1 
          fi
          shift # Remove key from processing
          shift # Remove value from processing
        ;;
        -admin-password)
          ADMIN_PASSWORD="$2"
          ADMIN_PASSWORD=`echo "$ADMIN_PASSWORD" | tr -d '"\047,\\\/'`
          echo "Admin Password:  $ADMIN_PASSWORD"
          if [[ ! "$ADMIN_PASSWORD" ]]; then 
            echo "$1 should be called with a value"
            exit 1 
          fi
          shift # Remove key from processing
          shift # Remove value from processing
        ;;
        --private-network)
          PRIVATE_NETWORK="$2"
          if [[ ! valid_cidr_network($PRIVATE_NETWORK) ]]; then
            echo "Private network should be a valid TCPIP Network with CIDR - example 10.244.0.0/16"
            exit 1
          fi
          shift # remove key from processing
          shift # Remove value from processing
        ;;
        -h|--help|-?)
          show_help
        ;;
    esac
done

exit 0
#
# Install kubernetes
#

# Step 1: Get Kubernetes from Google
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

# Step 2: Install the kubernetes tools
tdnf install kubeadm kubectl kubelet -y

# STep 3: start kubelet
systemctl enable --now kubelet

#
# Initialize the kubernetes cluster
#
kubeadm config images pull
kubeadm init --pod-network-cidr=10.244.0.0/16 | tee ~/kubernetes/kubeadm-init.log

#
# Create the admin user
#

if [[ $(id -u $ADMIN_USER) ]]; then
    echo "Creating Admin user '$ADMIN_USER'"
    useradd -m -G sudo -s /bin/bash $ADMIN_USER
    echo -e "$ADMIN_PASSWORD\n$ADMIN_PASSWORD" | passwd $ADMIN_USER
    cp /etc/kubernetes/admin.conf /home/$ADMIN_USER/
    sudo chown $(id -u kubeadm):$(id -g kubeadm) /home/$ADMIN_USER/admin.conf
else
    echo "$ADMIN_USER already exists"
fi
echo "export KUBECONFIG=/home/$ADMIN_USER/admin.conf" | tee -a /home/$ADMIN_USER/.bashrc

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