#!/bin/bash

n_workers=2
port_base=9000

export PYTHONUNBUFFERED=TRUE
# -p $host_port:8080
# --net=host \
for ((i=0; i<n_workers; i++))
do
  host_port=$((port_base+i))
  json_event="test_input_worker${i}.json"
  sudo docker run  \
    -v ~/fileshare:/app/data \
    -a stdout -a stderr \
    -e JSON_EVENT="$json_event" \
    "linear_ec_2_worker:test" > output${i}.txt 2>&1 & 
done