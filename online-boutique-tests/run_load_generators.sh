#!/bin/bash

IP=$1
PORT=$2

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

LOAD_GEN_PATH="${DIR}/load-generator/"

if [ -z "$IP" ] || [ -z "$PORT" ]; then
  echo "Usage: $0 <IP> <Port>"
  exit 1
fi

echo "Creating separate directory for each Locust worker..."
for j in {1..17}
do
    if [ ! -d "locust_worker_${j}/" ] ; then
      echo "locust_worker_${j}/ DOES NOT exists."
      cp -r $LOAD_GEN_PATH locust_worker_${j}/
    fi
    # sleep 1
done

if [ -z "$TMUX" ]; then
  if [ -n "`tmux ls | grep locust`" ]; then
    tmux kill-session -t locust
  fi
  tmux new-session -d -s locust -n demo "${DIR}/set_tmux_worker.sh $IP $PORT"
fi