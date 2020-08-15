#!/bin/bash
#set -eo xtrace

#
# Default values of arguments
#
ADMIN_USERNAME="kubeadmin"          # Local Linux User to admin kubenetes from
ADMIN_PASSWORD="VMware1!"           # kubernetes admin password
INTERNAL_NETWORK="10.244.0.0/16"    # Internal kubernetes newtork for calico


#
# Function to make it easy to what step is being exeucted
#
step() {
  local STEP_TEXT=$1
  echo
  echo
  echo "#############################################"
  echo "$STEP_TEXT"
  echo "#############################################"
  echo 
  echo
}


#
# Show help
#
show_help() {
cat << EOF
usage: installK8S-Master [--admin-username name] [--admin-password password] [--internal-network cidr-network][--get-join-params] [-t--test] [-?|-h|--help]
  options:
    --admin-username  {username}        Local linux user to admin kubernetes from
    --admin-password  {password}        Password for the kubernetes admin user
    --internL-network {cidr-network}    Internal kubernetes network for calico
    --get-join-params                   Retrieve the parameters necessary to join a node to this cluster
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
# Get the join params for cluster if you need them later
#
get_join_params() {
CERT_HASH=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt \
| openssl rsa -pubin -outform der 2>/dev/null \
| openssl dgst -sha256 -hex \
| sed 's/^.* //')
TOKEN=$(kubeadm token list -o json | jq -r '.token' | head -1)
IP=$(kubectl get nodes -lnode-role.kubernetes.io/master -o json \
| jq -r '.items[0].status.addresses[] | select(.type=="InternalIP") | .address')
PORT=6443

cat << EOF
To install nodes, you will need the following values for the installK8S-Node.sh script:

  cluster: https://$IP:$PORT

  token: $TOKEN

  discovery-token-ca-cert-hash: CERT_HASH

Alternately, you can copy the contents of the /root/kubernetes directory to the same location on the node.

EOF
}

#
# Process Command line Arguments
#
for arg in "$@"
do
    case $arg in
        --get-join-params)      
          get_join_params
          exit 0
        ;;
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
          CAPTURE_NETWORK="$2"
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
        ;;
        -h|--help|-?)
          show_help
        ;;
    esac
done



#
# Add Google kubernetes repository to OS
#
step "Adding the Google kubernetes epository"
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
step "Install kubernetes tools and enable kubelet"

tdnf install kubeadm kubectl kubelet -y
systemctl enable --now kubelet

#
# Initialize the kubernetes cluster
#
step "installing kubernetes"
kubeadm config images pull
kubeadm init --pod-network-cidr=$INTERNAL_NETWORK | tee ~/kubernetes/kubeadm-init.log

#
# Create the admin user
#
step "Creating the kubernetes admin user"
if id -u "$ADMIN_USERNAME" >/dev/null 2>&1; then
  echo "$ADMIN_USERNAME already exists, skipping creation"
else
  echo "Creating user $ADMIN_USERNAME"
  useradd -m -G sudo -s /bin/bash $ADMIN_USERNAME
  echo -e "VMware1!\nVMware1!" | passwd $ADMIN_USERNAME >/dev/null
  cp /etc/kubernetes/admin.conf /home/$ADMIN_USERNAME/
  sudo chown $(id -u $ADMIN_USERNAME):$(id -g $ADMIN_USERNAME) /home/$ADMIN_USERNAME/admin.conf
  echo "export KUBECONFIG=/home/$ADMIN_USERNAME/admin.conf" | tee -a /home/$ADMIN_USERNAME/.bashrc
fi

#
# Export kubeadm info for root (note this violates kubernetes common admin practices)
#
step "Exporting kubeadm config to root"
export KUBECONFIG=/etc/kubernetes/admin.conf
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> /root/.bashrc
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> /root/.bash_profile

#
# Install networking (I'm using calico, you can opt for something else)
#
step "Installing Calico for kubernetes newtorking"
kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml

# Get the Calico network profile and match up the CIDR Range
 wget -O - https://docs.projectcalico.org/manifests/calico.yaml | sed -E -e 's/# - name: CALICO_IPV4POOL_CIDR/- name: CALICO_IPV4POOL_CIDR/' -e "s+#   value: \"192.168.0.0/16\"+  value: \"$INTERNAL_NETWORK\"+g" | kubectl apply -f -


step "Allowing the master node to be a scheduling node"
# Allow scheduling of pods on this node
kubectl taint nodes --all node-role.kubernetes.io/master:NoSchedule-
echo << EOF
#############################################
#############################################

Installation is now complete for the master node.
EOF
get_join_params
