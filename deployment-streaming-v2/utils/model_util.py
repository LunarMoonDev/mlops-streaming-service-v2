import base64
import json
import os

import mlflow


def get_model_location(run_id):
    """
    returns model location that sits in local
    """
    model_location = os.getenv('MODEL_LOCATION')

    if model_location is not None:
        return model_location

    model_bucket = os.getenv('MODEL_BUCKET', 'mlflow-buckets')
    model_location = f's3://{model_bucket}/{run_id}/artifacts/model'

    return model_location


def load_model(run_id):
    """
    creates model instance via mlflow
    """
    model_path = get_model_location(run_id)
    model = mlflow.pyfunc.load_model(model_path)
    return model


def base64_decode(encoded_data):
    """
    decodes a bas64 encoded
    """
    decoded_data = base64.b64decode(encoded_data).decode('utf-8')
    ride_event = json.loads(decoded_data)
    return ride_event
