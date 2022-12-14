#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

ALTERNATIVE=$1

if [ -z "$ALTERNATIVE" ] ; then
  echo "Usage: $0 <grpc>"
  exit 1
fi

STAT_PATH="${DIR}"

cd $STAT_PATH

echo "Deleting the old stats files..."
rm $STAT_PATH/latency_of_each_req_stats_${ALTERNATIVE}.csv

echo "Consolidating Locust stats files from each Locust worker..."
for j in {2..17}
do
    if [ ! -d "locust_worker_${j}/" ] ; then
      echo "locust_worker_${j}/ DOES NOT exists."
      exit 1
    else
      cat $STAT_PATH/locust_worker_${j}/stats.csv >> $STAT_PATH/latency_of_each_req_stats_${ALTERNATIVE}.csv
    fi
done

cp $STAT_PATH/locust_worker_1/kn_stats_history.csv $STAT_PATH/rps_stats_${ALTERNATIVE}.csv