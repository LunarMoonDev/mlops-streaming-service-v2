import json
import base64

import mlflow

def load_model(run_id):
    logged_model = f's3://mlflow-buckets/{run_id}/artifacts/model'
    model = mlflow.pyfunc.load_model(logged_model)
    return model

def base64_decode(encoded_data):
    decoded_data = base64.b64decode(encoded_data).decode('utf-8')
    ride_event = json.loads(decoded_data)
    return ride_event