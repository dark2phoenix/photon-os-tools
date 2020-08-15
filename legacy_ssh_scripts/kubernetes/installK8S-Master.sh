#!/bin/bash

#
# Default values of arguments
#
ADMIN_USERNAME="kubeadmin"          # Local Linux User to admin kubenetes from
ADMIN_PASSWORD="VMware1!"           # kubernetes admin password
INTERNAL_NETWORK="10.244.0.0/16"    # Internal kubernetes newtork for calico

#
# Show help
#
show_help() {
cat << EOF
usage: captureLogLoop [-n|--name test_name] [-i|--iterations captures_to_collect] [-c|--cold-storage] [-t--test] [-?|-h|--help]
  options:
    --admin-username  {username}        Local linux user to admin kubernetes from
    --admin-password  {password}        Password for the kubernetes admin user
    --internL-network {cidr-network}    Internal kubernetes network for calico
    -?, -h, --help                      Show this help
EOF
exit 0
}

#
# Function to validate cidr network
#
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
# Process Command line Arguments
#
for arg in "$@"
do
    case $arg in
        --admin-username)      
          CAPTURE_NAME="$2"
          if [[ ! "$CAPTURE_NAME" ]]; then 
            echo "$1 should be called with a value"
            exit 1 
          else 
            # add in the _ for the eventual filename
            ADMIN_USERNAME=$2
          fi
          shift # Remove key from processing
          shift # Remove value from processing
        ;;
        --admin-password)      
          CAPTURE_PASSWORD="$2"
          if [[ ! "$CAPTURE_PASSWORD" ]]; then 
            echo "$1 should be called with a value"
            exit 1 
          else 
            # add in the _ for the eventual filename
            ADMIN_PASSWORD=$2
          fi
          shift # Remove key from processing
          shift # Remove value from processing
        ;;
        --internal-network)      
          CAPTURE_network="$2"
          if [[ ! "$CAPTURE_NETWORK" ]]; then 
            echo "$1 should be called with a value"
            exit 1 
          else 
            INTERNAL_NETWORK=$2
            VALID_NETWORK=$(valid_cidr_network $INTERNAL_NETWORK)

            if ( $VALID_NETWORK -ne "1"); then
                echo "$2 should be a valid TCPIP network in CIDR notation"
                echo "  -example:  10.244.0.0/16"
                exit 1
            fi
          fi
          shift # Remove key from processing
          shift # Remove value from processing
        -h|--help|-?)
          show_help
        ;;
    esac
done


#
# Add Google kubernetes repository to OS
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

#
# Install core kubernetes utils and enable kublet
#

tdnf install kubeadm kubectl kubelet -y
systemctl enable --now kubelet

#
# Initialize the kubernetes cluster
#
kubeadm config images pull
kubeadm init --pod-network-cidr=$INTERNAL_NETWORK | tee ~/kubernetes/kubeadm-init.log

#
# Create the admin user
#

if [[ $(id -u $ADMIN_USERNAME) -gt 0 ]]; then 
    echo "$ADMIN_USERNAME already exists, skipping creation"
else
    echo "Creating user $ADMIN_USERNAME"
    useradd -m -G sudo -s /bin/bash $ADMIN_USERNAME
    echo -e "VMware1!\nVMware1!" | passwd $ADMIN_USERNAME
    cp /etc/kubernetes/admin.conf /home/$ADMIN_USERNAME/
    sudo chown $(id -u $ADMIN_USERNAME):$(id -g $ADMIN_USERNAME) /home/$ADMIN_USERNAME/admin.conf
    echo "export KUBECONFIG=/home/$ADMIN_USERNAME/admin.conf" | tee -a /home/$ADMIN_USERNAME/.bashrc
fi
#
# Export kubeadm info for root because I'm too lazy to su
#
export KUBECONFIG=/etc/kubernetes/admin.conf
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> /root/.bashrc
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> /root/.bash_profile

#
# Install networking (I'm using calico, you can opt for something else)
#
wget https://docs.projectcalico.org/manifests/calico.yaml | sed -R "s+192.168.0.0/16+$INTERNAL_NETWORK+g" | kubectl apply -f -