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

AWS resources used:
- Lambda
    - Lambda 1: configuring and invoking a pool of Lambda 2
    - Lambda 2: training script for each worker
- S3
- ElastiCache for Memcached
- VPC
- CloudWatch

Dataset: [Higgs](https://www.csie.ntu.edu.tw/~cjlin/libsvmtools/datasets/binary.html#HIGGS)

Hyperparams of the training:
- Number of workers: `<n_workers>`
  - Specifies the number of workers used for parallel training. To distribute among <n_workers>, you'll need <n_workers> partitions of the dataset.

**Setup Steps**

1. Configure the AWS CLI

```bash
aws configure
```

Also, store AWS environmental variables for easier reference in later steps.
 ```bash
export AWS_ACCESS_KEY_ID=<AWS_ACCESS_KEY_ID>
export AWS_SECRET_ACCESS_KEY=<AWS_SECRET_ACCESS_KEY>
export AWS_ACCOUNT_ID=<AWS_ACCOUNT_ID>
export REGION_NAME=<REGION_NAME>
 ```

2. Prepare AWS Resources with AWS console

- A VPC. And create the endpoint to privately connect VPC to S3 (choose com.amazonaws.region.s3 as the service name).
- An Elasticache cluster for Memcached, used for gradient exchange in distributed training. Detailed configurations may refer to the [video](https://www.youtube.com/watch?v=58PMo2N8rxA). Copy the "configuration endpoint" for later use.
- An S3 bucket, named as `<data_bucket>`, to store machine learning dataset
- A Lambda execution role. Assign necessary permissions:
    - AmazonAPIGatewayInvokeFullAccess
    - AmazonEC2FullAccess
    - AmazonElastiCacheFullAccess
    - AmazonS3FullAccess
    - AWSKeyManagementServicePowerUser
    - AWSLambda_FullAccess
    - AWSLambdaRole
    - CloudWatchFullAccess
    - VPCLatticeServicesInvokeAccess

  Store the ARN (Amazon Resource Names) of the role for later reference. 
  ```bash
  export LAMBDA_ROLE_ARN=<LAMBDA_ROLE_ARN>
  ```

3. Download, partition, and upload dataset to S3

```bash
cd linear_ec
wget https://www.csie.ntu.edu.tw/~cjlin/libsvmtools/datasets/binary/HIGGS.xz
python partition_data.py \
  --file-path HIGGS.xz \
  --n-workers <n_workers> \
  --bucket-name <data_bucket> \
  --use-dummy-data  # 10 samples per partition
```

4. Setting training configurations in the handler of [Lambda 1](linear_ec/lambda1/linear_ec_1.py).

- Set `host` as the "configuration endpoint" of the Memcached
- Set `n_workers` and`data_bucket`
- (optional) modifying other hparams

5. Deploying function package on AWS Lambda with the [build script](linear_ec/build_lambda.sh):
```bash
bash build_lambda.sh
```

6. Invoking the Lambda function
```bash
aws lambda invoke --function-name linear_ec_1 /dev/stdout
```

7. Open CloudWatch and Check logs 

8. (Optional) Updating the function code

You must build, tag, upload the new image again. Then update the Lambda function with the new image, e.g.:
```bash
aws lambda update-function-code \
  --function-name linear_ec_2 \
  --image-uri "${AWS_ACCOUNT_ID}.dkr.ecr.${REGION_NAME}.amazonaws.com/linear_ec_2:latest"
```

**Debug Steps**

After building the image of the lambda, we can test it locally. 

For instance, let's consider testing the image of `linear_ec_2`.
1. Prepare the input event as json file
```bash
python linear_ec/lambda1/save_1_worker_output.py
```
2. Start the Docker image
```bash
docker run -p 9000:8080 \
  -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
  -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
  -e AWS_ACCOUNT_ID="$AWS_ACCOUNT_ID \
  -e REGION_NAME="$REGION_NAME" \
  docker-image:test
```
3. From a new terminal window, post the event to the following endpoint
```bash
curl "http://localhost:9000/2015-03-31/functions/function/invocations" \
  -H "Content-Type: application/json" \
  -d @linear_ec/lambda1/test_input_1_worker.json
```

## Discussions

### Deploying Lambda functions with container images instead of zip
An AWS Lambda function's code consists of your function's handler code and any required libraries. To deploy this function code to Lambda, you have two options: a .zip file archive or a container image. While using a .zip package offers shorter cold start times compared to a container package, AWS imposes size limits (50MB zipped and 250MB unzipped). Even the use of layers (with a 256MB quota) for additional storage may not support large packages. For instance, packaging PyTorch in a .zip file is not feasible due to the large size of the torch package. For example, torch-1.0.1-py37 without CUDA is 219MB, while the version with CUDA support exceeds 1.1GB.

### Creating Lambda functions with AWS Lambda API instead of SAM
There are two technical approaches to creating Lambda functions:

- Serverless Application Model (SAM) in YAML: A comprehensive solution for creating and configuring various AWS resources, including Lambda functions, S3, Memcached, and more.
- Creating Lambda functions using the AWS Lambda API from the command line interface (CLI) and other AWS resources via the AWS Management Console.

Ultimately, the second approach is chosen primarily because SAM enforces a memory size limit of 3008 MB in some regions (e.g., us-west-1). In contrast, the AWS Lambda API allows you to create functions with up to 10 GB of memory.