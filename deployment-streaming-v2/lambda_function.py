import os
import model

PREDICTION_STREAM_NAME = os.getenv('PREDICTION_STREAM_NMAE', 'ride_predictions')
RUN_ID = os.getenv('RUN_ID')
TEST_RUN = os.getenv('TEST_RUN', 'False') == 'True'

model_service = model.init(PREDICTION_STREAM_NAME, RUN_ID, TEST_RUN)

def lambda_handler(event, context):
    return model_service.lambda_handler(event)