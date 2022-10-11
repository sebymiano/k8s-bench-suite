#!/bin/bash

COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_OFF='\033[0m' # No Color

POLYKUBE_FOLDER="/local/polykube"
CONFIG_MAP_FILE="config_map.yaml"

function show_help() {
usage="$(basename "$0") -d [polykube_base_dir]
Polykube-k8s start script

mode:
  -d: set Polykube directory (default to ${POLYKUBE_FOLDER})"
echo "$usage"
echo
}

while getopts :dh option; do
 case "${option}" in
 h|\?)
  show_help
  exit 0
  ;;
 r) POLYKUBE_FOLDER=${OPTARG}
	;;
 :)
  echo "Option -$OPTARG requires an argument." >&2
  show_help
  exit 0
  ;;
 esac
done

set -e
echo -e "${COLOR_GREEN}[ INFO ] Start Polykube CNI ${COLOR_OFF}"
pushd .

if [ ! -d "$POLYKUBE_FOLDER" ] 
then
    echo -e "${COLOR_RED} Directory $POLYKUBE_FOLDER DOES NOT exists. ${COLOR_OFF}" 
    exit 0
fi

cd $POLYKUBE_FOLDER
API_SERVER_ADDR=$(kubectl -n kube-system get pod -l component=kube-apiserver -o=jsonpath="{.items[0].metadata.annotations.kubeadm\.kubernetes\.io/kube-apiserver\.advertise-address\.endpoint}")

IFS=: read -r API_SERVER_HOST API_SERVER_PORT <<< ${API_SERVER_ADDR}

sed -i -E "s/(apiServerIp:\s*)\".*\"/\1\"${API_SERVER_HOST}\"/" manifests/${CONFIG_MAP_FILE}
sed -i -E "s/(apiServerPort:\s*)\".*\"/\1\"${API_SERVER_PORT}\"/" manifests/${CONFIG_MAP_FILE}

sed -i -E "s/(enableMorpheusDynamicOpts:\s*)\".*\"/\1\"false\"/" manifests/${CONFIG_MAP_FILE}
sed -i -E "s/(morpheusLogLevel:\s*)\".*\"/\1\"OFF\"/" manifests/${CONFIG_MAP_FILE}

kubectl apply -f manifests
popd

echo -e "${COLOR_GREEN}[ INFO ] Polykube CNI started, wait until all service boot up.${COLOR_OFF}"
sleep 90

echo -e "${COLOR_GREEN}[ INFO ] Restart all containers ${COLOR_OFF}"
kubectl get pods --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,HOSTNETWORK:.spec.hostNetwork --no-headers=true | grep '<none>' | awk '{print "-n "$1" "$2}' | xargs -L 1 -r kubectl delete pod