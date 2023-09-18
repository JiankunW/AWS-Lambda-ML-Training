#!/bin/bash
n_workers=2

for ((i=0; i<n_workers; i++))
do
  export JSON_EVENT="test_input_worker${i}.json"
  python linear_ec_2.py > output${i}_host.txt &
done