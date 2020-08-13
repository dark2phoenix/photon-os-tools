#!/bin/bash
#
#  Process command line argument for service account name
#
$SERVICE_ACCOUNT=$1

if [[ -z $SERVICE_ACCOUNT ]]; then
    echo "Enter the name of the service account"
    read $SERVICE_ACCOUNT
fi
#
# Create the service account for vra in the system namespace
#

cat > /root/kubernetes/svc-vra-rbac-config.yaml<<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: [SERVICE_ACCOUNT]
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: [SERVICE_ACCOUNT] 
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: [SERVICE_ACCOUNT]
    namespace: kube-system
EOF

sed -EN "s/[SERVICE_ACCOUNT]/$SERVICE_ACCOUNT/"

kubectl create -f /root/kubernetes/svc-vra-rbac-config.yaml

echo "Bearer Token for use with vRA:" 
echo 
kubectl describe secret $(kubectl get secrets -n kube-system | grep svc-vra | cut -d ' ' -f 1) -n kube-system | grep token | awk -F"token:[ ]+" '{print $2}'
echo 
echo 
echo "CA.crt in use by kubernetes cluster:"
echo  
kubectl get secret $(kubectl get secrets -n kube-system | grep svc-vra | cut -d ' ' -f 1) -n kube-system -o yaml | grep ca.crt | awk -F"ca.crt:[ ]+" '{print $2}'| head -n 1 | base64 -d
echo  