import os

import boto3


def create_kinesis_client():
    """
    creates kinesis client with endpoint from env var
    """
    endpoint_url = os.getenv('KINESIS_ENDPOINT_URL')

    if endpoint_url is None:
        return boto3.client('kinesis')

    return boto3.client('kinesis', endpoint_url=endpoint_url)
