#!/bin/bash

COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_OFF='\033[0m' # No Color

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function disable_kube_proxy {
  set -x
  kubectl patch ds -n kube-system kube-proxy -p '{"spec":{"template":{"spec":{"nodeSelector":{"non-calico": "true"}}}}}'
  set +x
}

echo -e "${COLOR_YELLOW}[ INFO ] Before starting make sure you have created the cluster with kube-proxy disabled ${COLOR_OFF}"
echo -e "${COLOR_YELLOW}[ INFO ] Command: sudo kubeadm init --skip-phases=addon/kube-proxy ${COLOR_OFF}"

echo -e "${COLOR_YELLOW}[ INFO ] If you don't want to re-create the cluster, I can disable kube-proxy for you ${COLOR_OFF}"

while true; do
    read -p "Do you want to do it? (y or n)." yn
    case $yn in
        [Yy]* ) disable_kube_proxy; break;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
done

while true; do
    read -p "Do you want to continue? (y or n)." yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

API_SERVER_ADDR=$(kubectl -n kube-system get pod -l component=kube-apiserver -o=jsonpath="{.items[0].metadata.annotations.kubeadm\.kubernetes\.io/kube-apiserver\.advertise-address\.endpoint}")

IFS=: read -r API_SERVER_HOST API_SERVER_PORT <<< ${API_SERVER_ADDR}

echo -e "${COLOR_GREEN}[ INFO ] Install Tigera operator ${COLOR_OFF}"
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.1/manifests/tigera-operator.yaml

echo -e "${COLOR_GREEN}[ INFO ] Apply config map with ${API_SERVER_ADDR} ${COLOR_OFF}"
kubectl apply -f - <<EOF
kind: ConfigMap
apiVersion: v1
metadata:
  name: kubernetes-services-endpoint
  namespace: tigera-operator
data:
  KUBERNETES_SERVICE_HOST: "${API_SERVER_HOST}"
  KUBERNETES_SERVICE_PORT: "${API_SERVER_PORT}"
EOF
kubectl delete pod -n tigera-operator -l k8s-app=tigera-operator

sleep 90


echo -e "${COLOR_GREEN}[ INFO ] Install custom resources ${COLOR_OFF}"
kubectl create -f ${DIR}/custom-resources.yaml

echo -e "${COLOR_GREEN}[ INFO ] Restart all containers ${COLOR_OFF}"
kubectl get pods --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,HOSTNETWORK:.spec.hostNetwork --no-headers=true | grep '<none>' | awk '{print "-n "$1" "$2}' | xargs -L 1 -r kubectl delete pod