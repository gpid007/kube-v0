#!/bin/bash

# source
https://github.com/big-data-europe/docker-spark

cat <<EOF >/root/dockerBuild/greg/spark/spark-service.yaml
add text here
EOF

kubectl create -f spark-service.yaml