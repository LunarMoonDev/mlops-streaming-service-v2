Unfortunately, AWS ECR is a pro feature (or not yet umplemented) in localstack; hence, i gave up implementing this at the moment.
However, here's how you run the notebook via docker-compose

### Requirements:
- ensure `AWS_PROFILE` exists
- ensure model exist in registry (run `model_linear` in `experiment-tracking` project)

### Running the integration tests (with local model)
- for this to work, download the model from registry and place it inside `integration_tests/model` directory
- make sure `MODEL_LOCATION` is present in `kinesis.yaml`
- make `run.sh` executable with `chmod +x` command
- run `./run.sh` and it will output the logs for integration testing

### Running the integration tests (with s3)
- edit the environment variable in `kinesis.yaml` to include the following
```yaml
  - AWS_ENDPOINT_URL=http://localstack:4566
  - AWS_DEFAULT_REGION=us-east-1
  - AWS_DEFAULT_OUTPUT=json
  - AWS_ACCESS_KEY_ID=test
  - AWS_SECRET_ACCESS_KEY=test
  - RUN_ID=579f0d6272e640c0907ce0f6137a6ec8
```
- make sure model registry is present with the `run_id` model
- make `run.sh` executable wiht `chmod` and run it
- run `./run.sh` and it will output the logs for integration testing
