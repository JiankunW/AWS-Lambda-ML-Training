#!/bin/bash

container_ids=$(sudo docker ps -q)

for container_id in $container_ids
do
  sudo docker kill $container_id
done