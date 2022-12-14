#!/bin/bash

COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_OFF='\033[0m' # No Color

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function cleanup {
    set +e
    kubectl taint nodes --all node-role.kubernetes.io/control-plane-
    sudo killall locust
    tmux kill-session -t locust
    sudo rm -rf locust_worker_*
}

trap cleanup EXIT

tmp_nodes=$(kubectl get nodes -o wide | grep 'control-plane' | awk '{if (NR!=1) {print $1}}')

nodes_str="${tmp_nodes//$'\n'/ }"
read -a nodes <<< "$nodes_str"

echo -e "${COLOR_YELLOW}[ INFO ] I will add a taint on the control plane node ${COLOR_OFF}"
for node in "${nodes[@]}"; do
    kubectl taint nodes ${node} node-role.kubernetes.io/control-plane=:NoSchedule
done

echo -e "${COLOR_GREEN}[ INFO ] Now it is time to deploy the services ${COLOR_OFF}"
kubectl apply -f manifests


kubectl wait pods -l app=frontend --for condition=Ready --timeout=360s

service_ip=$(kubectl get po -l app=frontend -o wide | awk '{if (NR!=1) {print $6}}')

echo -e "${COLOR_GREEN}[ INFO ] Got Service IP for Frontend Service: ${service_ip} ${COLOR_OFF}"

sleep 10

echo -e "${COLOR_GREEN}[ INFO ] Let's start the locust generator ${COLOR_OFF}"
${DIR}/run_load_generators.sh $service_ip 8080

sleep 20
tmp_locust_pids=$(pgrep locust)

echo $tmp_locust_pids

locust_pids_str="${tmp_locust_pids//$'\n'/ }"
read -a locust_pids <<< "$locust_pids_str"

echo -e "${COLOR_GREEN}[ INFO ] Wait until the test finishes ${COLOR_OFF}"
# wait for all pids
for pid in "${locust_pids[@]}"; do
    while [ -e /proc/$pid ]; do
        echo "Process: $pid is still running"
        sleep 5
    done
done

sleep 10

echo -e "${COLOR_GREEN}[ INFO ] Let's consolidate the results ${COLOR_OFF}"
${DIR}/consolidate_locust_stats.sh grpc

sudo rm -rf locust_worker_*