import json
import logging 

import requests
from deepdiff import DeepDiff

# config
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - [%(levelname)s]: %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)

with open('event.json', 'rt', encoding='utf-8') as f_in:
    event = json.load(f_in)

url = 'http://localhost:8080/2015-03-31/functions/function/invocations'
actual_response = requests.post(url=url, json=event).json()
logging.debug(f'actual response: {actual_response}')
logging.debug(f'json data: {json.dumps(actual_response, indent=2)}')

expected_response = {
    'predictions': [
        {
            'model': 'ride_duration_prediction_model',
            'version': 'IntegrationTestRunID',
            'prediction': {
                'ride_duration': 22.1,
                'ride_id': 256,
            },
        }
    ]
}

diff = DeepDiff(actual_response, expected_response, significant_digits=1)
logging.info(f'diff: {diff}')

assert 'type_changes' not in diff, 'assertion fail, different types detected. Please check diff'
assert 'values_changed' not in diff, 'assertion fail, different values detected. Please check diff'