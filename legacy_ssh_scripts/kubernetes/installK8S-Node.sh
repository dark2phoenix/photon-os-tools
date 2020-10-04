#!/bin/bash
#set -eo xtrace

#
# Default values of arguments
#
TOKEN=""                       # Kubernetes discovery token to allow node to join
DISCOVERY_CA_CERT_HASH=""      # CA Cert Hash of the discovery token for the Kubernetes cluster

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
usage: installK8S-Node [--clustsser cluster] [--token token] [--discovery-ca-cert-hash discovery-ca-cert-hash] [-?|-h|--help]
  options:
    --cluster {cluster}                                   Kubernetes clusteer URL with port e.g. https://172.28.5.120:6443
    --token  {token}                                      Discovery token for the kubernetes cluster
    --discovery-ca-cert-hash  {discovery-ca-cert-hash}    CA Cert Hash of the kubernetes discovery token
    -?, -h, --help                                        Show this help

  If the cluster, token and cert-hash are not specified, the script will look for /kubernetes/kubeadm-init.log in the home
  directory of the installation user.  This file was created by the installK8S-Master.sh script in the home directory
  of the user used to deploy kubernetes to the master node.
EOF
exit 0
}

#
# Process Command line Arguments
#
for arg in "$@"
do
    case $arg in
        --cluster)      
          CAPTURE_CLUSTER="$2"
          if [[ ! "$CAPTURE_CLUSTER" ]]; then 
            echo "$1 should be called with a value"
            exit 1 
          else 
            CLUSTER=$2
            if [[ ! $CLUSTER =~ '^(https?://.*):(\d+)\/?$' ]]; then
                echo "--cluster should be a valid kubernetes url:  e.g. https://172.28.10.100:6443" 
                exit 1
          fi
          shift # Remove key from processing
          shift # Remove value from processing
        ;;
        --token)      
          CAPTURE_TOKEN="$2"
          if [[ ! "$CAPTURE_TOKEN" ]]; then 
            echo "$1 should be called with a value"
            exit 1 
          else 
            TOKEN=$2
          fi
          shift # Remove key from processing
          shift # Remove value from processing
        ;;
        --discovery-ca-cert-hash)      
          CAPTURE_CERT_HASH="$2"
          if [[ ! "$CAPTURE_CERT_HASH" ]]; then 
            echo "$1 should be called with a value"
            exit 1 
          else 
            # add in the _ for the eventual filename
            DISCOVERY_CA_CERT_HASH=$2
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
# Ensure that we've got the master kubeadm-init.log before
# we start
#
SET_FROM="command line arguments"
if ! ( [-z "$CLUSTER"] && [-z "$TOKEN"] && [-z "$DISCOVERY_CA_CERT_HASH"] ) ; then
    if [ ! -f ~/kubernetes/kubeadm-init.log ]; then
        echo "Please copy the /root/kubernetes folder from the master to this "
        echo "user's home directory so the installation can begin"
        exit 1
    else 
      SET_FROM="~/kubernetes/kubeadm-init.log"
      CLUSTER=$(grep -A1 "kubeadm join.*$" ~/kubernetes/kubeadm-init.log | tr -d '\n' | tr -d '\\' | tr -s ' ' | cut -d ' ' -f3)
      TOKEN=$(grep -A1 "kubeadm join.*$" ~/kubernetes/kubeadm-init.log | tr -d '\n' | tr -d '\\' | tr -s ' ' | cut -d ' ' -f5)
      DISCOVERY_CA_CERT_HASH=$(grep -A1 "kubeadm join.*$" ~/kubernetes/kubeadm-init.log | tr -d '\n' | tr -d '\\' | tr -s ' ' | cut -d ' ' -f7)
    fi
fi

if ! ( [-z "$CLUSTER"] && [-z "$TOKEN"] && [-z "$DISCOVERY_CA_CERT_HASH"] ) ; then
    echo "ERROR - could not determine cluster, token and discovery_ca_cert_hash"
    echo "Variables read from $SET_FROM"
    echo "cluster: $CLUSTER"
    echo "token: $TOKEN"
    echo "discovery_ca_cert_hash: $DISCOVERY_CA_CERT_HASH"
    echo
    echo Please check values and try again.
    exit 1
fi

#
# Install kubernetes
#
step "Add Google kubernetes repository"
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

step "Install kubernetes tools and enable kubelet"
tdnf install kubeadm kubectl kubelet -y
systemctl enable --now kubelet

#
# Get the init string from kubeadm to get the join command
#
#eval $(grep -A1 "kubeadm join.*$" ~/kubernetes/kubeadm-init.log | tr -d '\n' | tr -d '\\')
step "Install kubernetes node"
kubeadm join $CLUSTER --token $TOKEN --discovery-token-ca-cert-hash $DISCOVERY_CA_CERT_HASH