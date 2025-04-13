from functools import lru_cache

from pydantic import Field, BaseModel

from utils.aws_util import create_ssm_client

# constants
PARAM_STORE_PARENT = '/streaming/config'


@lru_cache
def get_ssm_param(name: str) -> str:
    """
    Grabs given parameter from AWS parameter store
    """
    ssm = create_ssm_client()
    response = ssm.get_parameter(Name=name, WithDecryption=True)
    return response['Parameter']['Value']


def ssm_factory(param_name: str, cast_func=str):
    """
    grabs the prameter value from ssm with casting
    """
    return lambda: cast_func(get_ssm_param(param_name))


class ParamConfig(BaseModel):
    """
    Config class for Parameter store from AWS
    """

    prediction_stream_name: str = Field(
        default_factory=ssm_factory(f'{PARAM_STORE_PARENT}/prediction_stream_name')
    )
    run_id: str = Field(default_factory=ssm_factory(f'{PARAM_STORE_PARENT}/run_id'))
    debug: bool = Field(
        default_factory=ssm_factory(
            f'{PARAM_STORE_PARENT}/debug', lambda x: x.lower() == 'true'
        )
    )
