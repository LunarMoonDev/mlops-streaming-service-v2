from unittest.mock import Mock

from kinesis_stream import KinesisCallback


def test_put_record():
    """
    unit testing put_record from KinesisCallback
    """
    prediction_stream_name = 'sample_stream'
    mock_kinesis_client = Mock()
    mock_kinesis_client.put_record = Mock()

    mock_kinesis = KinesisCallback(mock_kinesis_client, prediction_stream_name)
    mock_kinesis.put_record({'prediction': {'ride_id': None}})

    mock_kinesis_client.put_record.assert_called_once()
