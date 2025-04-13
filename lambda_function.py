import model
from config import ParamConfig

config = ParamConfig()
model_service = model.init(config.prediction_stream_name, config.run_id, config.debug)


def lambda_handler(event, context):
    """
    entry function for aws lambda
    """
    # pylint: disable=unused-argument

    return model_service.lambda_handler(event)
