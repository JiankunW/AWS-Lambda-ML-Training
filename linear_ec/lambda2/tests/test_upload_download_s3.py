import boto3
import pytest
from io import BytesIO

S3_BUCKET_NAME = 'higgs-10'

@pytest.fixture
def s3_client():
    # Initialize an S3 client
    return boto3.client('s3')

@pytest.fixture
def sample_data():
    # Replace this with the data you want to upload
    return b'Your sample data'

def test_upload_and_download_data(s3_client, sample_data):
    # Upload data to S3
    s3_client.put_object(Bucket=S3_BUCKET_NAME, Key='test_data.txt', Body=sample_data)

    # Download the data from S3
    response = s3_client.get_object(Bucket=S3_BUCKET_NAME, Key='test_data.txt')
    downloaded_data = response['Body'].read()

    # Compare the downloaded data with the original data
    assert downloaded_data == sample_data