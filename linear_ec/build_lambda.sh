#!/bin/bash

# Set these environment variables before running
if [ -z "$AWS_ACCESS_KEY_ID" ] || \
   [ -z "$AWS_SECRET_ACCESS_KEY" ] || \
   [ -z "$AWS_ACCOUNT_ID" ] || \
   [ -z "$REGION_NAME" ] || \
   [ -z "$LAMBDA_ROLE_ARN" ]; then
    echo "One or more required AWS environment variables are not set. Please ensure that AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_ACCOUNT_ID, REGION_NAME, and LAMBDA_ROLE_ARN are all properly configured."
    exit 1
fi

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
