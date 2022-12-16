#!/bin/bash

COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_OFF='\033[0m' # No Color

if ! command -v helm &> /dev/null; then
    echo -e "${COLOR_RED}[ INFO ] Helm is not installed on the machine ${COLOR_OFF}"
    exit
fi

echo -e "${COLOR_YELLOW}[ INFO ] Before starting make sure you have created the cluster with kube-proxy disabled ${COLOR_OFF}"
echo -e "${COLOR_YELLOW}[ INFO ] Command: sudo kubeadm init --skip-phases=addon/kube-proxy ${COLOR_OFF}"

while true; do
    read -p "Do you want to continue? (y or n)." yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo -e "${COLOR_GREEN}[ INFO ] Installing Cilium CNI ${COLOR_OFF}"

API_SERVER_ADDR=$(kubectl -n kube-system get pod -l component=kube-apiserver -o=jsonpath="{.items[0].metadata.annotations.kubeadm\.kubernetes\.io/kube-apiserver\.advertise-address\.endpoint}")
IFS=: read -r API_SERVER_HOST API_SERVER_PORT <<< ${API_SERVER_ADDR}

set -x
helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium --version 1.12.2 \
    --namespace kube-system \
    --set kubeProxyReplacement=strict \
    --set k8sServiceHost=${API_SERVER_HOST} \
    --set k8sServicePort=${API_SERVER_PORT}

set +x
echo -e "${COLOR_GREEN}[ INFO ] Cilium CNI installed. Wait until all services boot up ${COLOR_OFF}"
kubectl wait --for=condition=Ready nodes --all --timeout=180s

sleep 10
set +e
kubectl taint nodes --all node-role.kubernetes.io/control-plane- > /dev/null 2>&1
set -e

echo -e "${COLOR_GREEN}[ INFO ] Restart all containers ${COLOR_OFF}"
kubectl get pods --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,HOSTNETWORK:.spec.hostNetwork --no-headers=true | grep '<none>' | awk '{print "-n "$1" "$2}' | xargs -L 1 -r kubectl delete pod --grace-period=15

echo -e "${COLOR_GREEN}[ INFO ] Installing Cilium CLI ${COLOR_OFF}"
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/master/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

cilium status --wait

kubectl -n kube-system exec ds/cilium -- cilium status | grep KubeProxyReplacement

while true; do
    read -p "Do you want to start the connectivity test? It takes ~5 mins (y or n)." yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

cilium connectivity test