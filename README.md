# AWS Lambda for ML Training

This repository demonstrates how to train a collection of Machine Learning models on AWS Lambda. It is built upon the project [LambdaML](https://github.com/DS3Lab/LambdaML/tree/master).

**Requirements**

- AWS Command Line Interface (AWS CLI) version 2
- Docker
- python3.7, torch-1.0.1, boto3, numpy

**Supported Algorithms**

- Linear Classification

**TO-DO**

- use AWS CLI instead to prepare AWS resources
- use AWS CLI to clean up AWS resources upon finish


## Examples

### [Linear Classification with Memcached](linear_ec)

AWS Resources used:
- Lambda
    - Lambda 1: configuring and invoking a pool of Lambda 2
    - Lambda 2: main training script
- S3: storing ML dataset
- ElastiCache for Memcached: gradient exchange in distributed training
- VPC
- CloudWatch

Dataset: [Higgs](https://www.csie.ntu.edu.tw/~cjlin/libsvmtools/datasets/binary.html#HIGGS)

**Setup Steps**

1. Prepare AWS Resources with AWS console

- Create an VPC. And create the endpoint to privately connect VPC to S3 (choose com.amazonaws.region.s3 as the service name).
- Create an Elasticache cluster. Detailed configurations may refer to the [video](https://www.youtube.com/watch?v=58PMo2N8rxA). Copy the "configuration endpoint" for later use.
- Create an S3 bucket.
- Create an Lambda execution role. Copy ARN for later use. Assign necessary permissions:
    - AmazonAPIGatewayInvokeFullAccess
    - AmazonEC2FullAccess
    - AmazonElastiCacheFullAccess
    - AmazonS3FullAccess
    - AWSKeyManagementServicePowerUser
    - AWSLambda_FullAccess
    - AWSLambdaRole
    - CloudWatchFullAccess
    - VPCLatticeServicesInvokeAccess

2. Download, partition, and upload dataset to S3

Consider the hparams: `n_workers`, `bucket_name` (must exist in S3)
```bash
cd linear_ec
wget https://www.csie.ntu.edu.tw/~cjlin/libsvmtools/datasets/binary/HIGGS.xz
python partition_data.py --file-path HIGGS.xz --n-workers 2 --bucket-name higgs-2 --use-dummy-data
```

3. Modifying some hparams in the handler of [Lambda 1](linear_ec/lambda1/linear_ec_1.py).

- Set `host` as the "configuration endpoint" in step 1
- Set `n_workers` and`data_bucket` as `n_workers` and `bucket_name` in step 2
- (optional) modifying other hparams

4. Deploying function package on AWS Lambda

Set environment variables and the role ARN set in step 1 in the top of the [build script](linear_ec/build_lambda.sh), and run:
```bash
bash build_lambda.sh
```

5. Invoking the Lambda function
```bash
aws lambda invoke --function-name linear_ec_1 /dev/stdout
```

6. Open CloudWatch and Check logs 

7. (Optional) Updating the function code

You must build, tag, upload the new image again. Then update the Lambda function with the new image:
```bash
aws lambda update-function-code --function-name linear_ec_2 --image-uri 051291761206.dkr.ecr.us-west-1.amazonaws.com/linear_ec_2:latest
```

**Debug Steps**

After building the image of the lambda, we test it locally. 

Take testing the image of `linear_ec_2` for example.
1. Prepare the input event as json file
```bash
python linear_ec/lambda1/save_1_worker_output.py
```
2. Start the Docker image
```bash
docker run -p 9000:8080 \
  -e AWS_ACCESS_KEY_ID=<AWS_ACCESS_KEY_ID> \
  -e AWS_SECRET_ACCESS_KEY=<AWS_SECRET_ACCESS_KEY> \
  -e AWS_ACCOUNT_ID=<AWS_ACCOUNT_ID> \
  -e REGION_NAME=<REGION_NAME> \
  docker-image:test
```
3. From a new terminal window, post the event to the following endpoint
```bash
curl "http://localhost:9000/2015-03-31/functions/function/invocations" -H "Content-Type: application/json" -d @linear_ec/lambda1/test_input_1_worker.json
```

## Discussions

### Deploying Lambda functions with container images instead of zip
An AWS Lambda function's code comprises your function's handler code, together with libraries your code depends on. To deploy this function code to Lambda, you use a deployment package. This package may either be a .zip file archive or a container image. You can benefit from zip package by shorter cold start time than the container package, but AWS has little quota for it (50MB zipped, and 250MB unzipped). Layer (256MB quota), which you may turn to for supplementary storage, also fails to support large package. For example, it is infeasible to package PyTorch in zip due to the torch package (e.g. torch-1.0.1+cpu-py37 is 219MB, torch-1.0.1-py37 with cuda 1.1G) is too big. 

### Creating Lambda functions with AWS Lambda API instead of SAM
Two technical routes of creating Lambda functions are:
1. Serverless Application Model (SAM) in YAML: one-stop solution for creating and configuring a collection of AWS resources: lambda, S3, Memcached, etc.
2. Creating Lambda functions using AWS Lambda API from CML, and other AWS resources on aws console. 

Finally, the second route is chosen since SAM specifies a memory size of 3008 MB in some regions (like us-west-1). In contrast, AWS Lambda API allows to create functions with up to 10,240 MB of memory.
