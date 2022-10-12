#!/bin/bash

COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_OFF='\033[0m' # No Color

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FLANNEL_CNI_FILE="kube-flannel.yml"

function show_help() {
usage="$(basename "$0")
Flannel CNI start script
"
echo "$usage"
echo
}

while getopts h option; do
 case "${option}" in
 h|\?)
  show_help
  exit 0
  ;;
 :)
  echo "Option -$OPTARG requires an argument." >&2
  show_help
  exit 0
  ;;
 esac
done

set -e
echo -e "${COLOR_GREEN}[ INFO ] Start Flannnel CNI ${COLOR_OFF}"

kubectl apply -f ${DIR}/${FLANNEL_CNI_FILE}

echo -e "${COLOR_GREEN}[ INFO ] Flannnel CNI started, wait until all services boot up.${COLOR_OFF}"
kubectl wait --for=condition=Ready nodes --all --timeout=90s

echo -e "${COLOR_GREEN}[ INFO ] Restart all containers ${COLOR_OFF}"
kubectl get pods --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,HOSTNETWORK:.spec.hostNetwork --no-headers=true | grep '<none>' | awk '{print "-n "$1" "$2}' | xargs -L 1 -r kubectl delete pod --grace-period=15