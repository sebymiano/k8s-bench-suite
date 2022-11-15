#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

KNB_FULL="${DIR}/../knb-full"

if [ $# -ne 1 ]; then
    echo "The first argument is the output file name"
    exit 1
fi

file_name=$1

${KNB_FULL} -sn node1.morpheus-k8s.morpheus-pg0.utah.cloudlab.us \
            -cn node2.morpheus-k8s.morpheus-pg0.utah.cloudlab.us \
            -o data -f ${file_name}.knbdata