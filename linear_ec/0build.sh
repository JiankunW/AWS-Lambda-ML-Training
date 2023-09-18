#!/bin/bash

n_workers=2

for ((i=0; i<n_workers; i++))
do
  # Build the Docker image with a unique tag for each worker
  sudo docker build --platform linux/amd64 -t "linear_ec_2_worker${i}:test" ./lambda2
done