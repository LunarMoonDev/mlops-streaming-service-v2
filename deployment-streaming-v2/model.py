import boto3
import pandas as pd

from utils.model_util import base64_decode, load_model
from kinesis_stream import KinesisCallback

class ModelService:
    def __init__(self, model, model_version=None, callbacks=None):
        self.model = model
        self.model_version = model_version
        self.callbacks = callbacks or []
    
    def prepare_features(self, ride):
        features = {}
        features['trip_distance'] = ride['trip_distance']
        features['PULocationID'] = ride['PULocationID']
        features['DOLocationID'] = ride['DOLocationID']

        return pd.DataFrame([features])

    def predict(self, features):
        pred = self.model.predict(features)
        return float(pred[0])
    
    def lambda_handler(self, event):
        prediction_events = []

        for record in event['Records']:
            encoded_data = record['kinesis']['data']
            ride_event  = base64_decode(encoded_data)

            ride = ride_event['ride']
            ride_id = ride_event['ride_id']

            features = self.prepare_features(ride)
            prediction = self.predict(features)

            prediction_event = {
                'model': 'ride_duration_prediction_model',
                'version': self.model_version,
                'prediction': {
                    'ride_duration': prediction,
                    'ride_id': ride_id
                }
            }

            for callback in self.callbacks:
                callback(prediction_event)

            prediction_events.append(prediction_event)

        return {
            'predictions': prediction_events
        }
    
def init(prediction_stream_name: str, run_id: str, test_run:bool):
    model = load_model(run_id)

    callbacks = []
    if not test_run:
        kinesis_client = boto3.client('kinesis')
        kinesis_callback = KinesisCallback(
            kinesis_client,
            prediction_stream_name
        )

        callbacks.append(kinesis_callback.put_record)
    
    model_service = ModelService(model=model, model_version=run_id, callbacks=callbacks)
    return model_service