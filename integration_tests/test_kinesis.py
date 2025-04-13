import os
import json
import logging

import boto3
from deepdiff import DeepDiff

# config
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - [%(levelname)s]: %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S',
)

kinesis_client = boto3.client('kinesis')

stream_name = os.getenv('PREDICTION_STREAM_NAME', 'output_streams')
SHARD_ID = 'shardId-000000000000'

shard_iterator_response = kinesis_client.get_shard_iterator(
    StreamName=stream_name, ShardId=SHARD_ID, ShardIteratorType='TRIM_HORIZON'
)

shard_iterator_id = shard_iterator_response['ShardIterator']

records_response = kinesis_client.get_records(ShardIterator=shard_iterator_id, Limit=1)

records = records_response['Records']
logging.info('Shard records: %s', records)


assert len(records) == 1

actual_records = json.loads(records[0]['Data'])
logging.info('1st Record Data: %s', actual_records)

# pylint: disable=duplicate-code
expected_record = {
    'model': 'ride_duration_prediction_model',
    'version': 'IntegrationTestRunID',
    'prediction': {
        'ride_duration': 22.1,
        'ride_id': 256,
    },
}

diff = DeepDiff(actual_records, expected_record, significant_digits=1)
logging.info('diff: %s', diff)

assert (
    'type_changes' not in diff
), 'assertion fail, different types detected. Please check diff'
assert (
    'values_changed' not in diff
), 'assertion fail, different values detected. Please check diff'
# pylint: enable=duplicate-code
