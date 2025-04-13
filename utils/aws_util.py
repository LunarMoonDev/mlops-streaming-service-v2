import boto3


def create_kinesis_client():
    """
    creates kinesis client with endpoint from env var
    """
    return boto3.client('kinesis')


def create_ssm_client():
    """
    creates ssm client
    """
    return boto3.client('ssm')
