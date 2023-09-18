#!/bin/bash


# Build the Docker image with a unique tag for each worker
sudo docker build --platform linux/amd64 -t "linear_ec_2_worker:test" ./lambda2
