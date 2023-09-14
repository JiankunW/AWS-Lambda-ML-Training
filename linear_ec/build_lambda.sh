#!/bin/bash

# Replace with yours
AWS_ACCESS_KEY_ID=<AWS_ACCESS_KEY_ID>
AWS_SECRET_ACCESS_KEY=<AWS_SECRET_ACCESS_KEY>
AWS_ACCOUNT_ID=<AWS_ACCOUNT_ID>
REGION_NAME=<REGION_NAME>
LAMBDA_ROLE_ARN=<LAMBDA_ROLE_ARN>

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$AWS_ACCOUNT_ID" ] || [ -z "$REGION_NAME" ] || [ -z "$LAMBDA_ROLE_ARN" ]; then
    echo "Error: some AWS environmental variables haven't set up."
    exit 1

# Step 1: Building the image
docker build --platform linux/amd64 -t linear_ec_1_image:test ./lambda1
docker build --platform linux/amd64 -t linear_ec_2_image:test ./lambda2

# Step 2: Deploying the image
aws ecr get-login-password --region ${REGION_NAME} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${REGION_NAME}.amazonaws.com

function_name_array=("linear_ec_1" "linear_ec_2")
for func_name in "${function_name_array[@]}"; do
    echo "Deploying ${func_name}..."
    aws ecr create-repository --repository-name ${func_name} --image-scanning-configuration scanOnPush=true --image-tag-mutability MUTABLE
    imageuri=${AWS_ACCOUNT_ID}.dkr.ecr.${REGION_NAME}.amazonaws.com/${func_name}:latest
    docker tag ${func_name}_image:test ${imageuri}
    docker push ${imageuri}
    aws lambda create-function \
        --function-name ${func_name} \
        --package-type Image \
        --code ImageUri=${imageuri} \
        --role ${LAMBDA_ROLE_ARN}
    echo "\n"
done

echo "Done!"
