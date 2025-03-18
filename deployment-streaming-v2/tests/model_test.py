from unittest.mock import Mock
import pandas as pd

import model

def test_prepare_features():
    model_service = model.ModelService(None)    
    ride = {
        "PULocationID": 130,
        "DOLocationID": 205,
        "trip_distance": 3.66
    }

    actual_features = model_service.prepare_features(ride)
    expected_features = pd.DataFrame([{
        "trip_distance": 3.66,
        "PULocationID": 130,
        "DOLocationID": 205
    }])

    pd.testing.assert_frame_equal(actual_features, expected_features)

def test_predict():
    mock_model = Mock()
    mock_model.predict.return_value = [10.0]

    model_service = model.ModelService(mock_model)
    features = pd.DataFrame([{
        "trip_distance": 3.66,
        "PULocationID": 130,
        "DOLocationID": 205
    }])

    prediction = model_service.predict(features)

    assert mock_model.predict.return_value[0] == prediction

def test_lambda_handler():
    run_id = 'laksdjflaksdjg'
    event = {"Records": [{
                "kinesis": {
                    "data": "ewogICAgICAgICJyaWRlIjogewogICAgICAgICAgICAiUFVMb2NhdGlvbklEIjogMTMwLAogICAgICAgICAgICAiRE9Mb2NhdGlvbklEIjogMjA1LAogICAgICAgICAgICAidHJpcF9kaXN0YW5jZSI6IDMuNjYKICAgICAgICB9LCAKICAgICAgICAicmlkZV9pZCI6IDI1NgogICAgfQ=="}}]}

    mock_model = Mock()
    mock_callback = Mock()

    mock_model.predict.return_value = [10.0]
    model_service = model.ModelService(model=mock_model, model_version=run_id, callbacks=[mock_callback])

    expected = model_service.lambda_handler(event)
    actual = {
        'predictions': [{
            'model': 'ride_duration_prediction_model',
            'version': 'laksdjflaksdjg',
            'prediction': {
                'ride_duration': 10.0,
                'ride_id': 256
            }
        }]
    }

    assert expected == actual
