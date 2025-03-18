Unfortunately, AWS ECR is a pro feature (or not yet umplemented) in localstack; hence, i gave up implementing this at the moment.
However, here's how you run the notebook via docker-compose

### Requirements:
- ensure `AWS_PROFILE` exists
- ensure model exist in registry (run `model_linear` in `experiment-tracking` project)

### Running the dockerfile
- Run the lambda server with `docker compose up`
    - it should open up a port 8080 which you can request to
- Run the pyhon model `test_lambda` (Note: make sure Pipenv is active)
    - it should request a kinesis based payload and output the prediction response


### For notes, here's how you setup the architecture in aws cli (RUN THIS WITH AWS SERVER NOT LOCALSTACK)
#### Create IAM role
```bash
# create role lambda-kinesis-role
aws iam create-role --role-name lambda-kinesis-role --assume-role-policy-document file://trust-policy.json
# attach policy AWSLambdaKinesisExecutionRole
aws iam attach-role-policy --role-name lambda-kinesis-role --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaKinesisExecutionRole
# for validation but it shows our role arn
aws iam get-role --role-name lambda-kinesis-role
```

#### Create ECR repository and push the image
```bash
# create docker image with our dockerfile
docker build -t stream-model-duration:v1 -f docker/streaming.dockerfile .
# create ecr repository in localstack
aws ecr create-repository --repository-name streaming-repo

# in aws, you might have to login to ecr before you push or pull; uri can be found from `aws ecr describe-repositories --region <region>` command
# [OPTIONAL] aws ecr get-login-password --region us-east-1 | docker login --username <username> --password-stdin <ecr registry url>

# tag our image with ecr uri
docker tag stream-model-duration:v1 localhost:4510/streaming-repo:latest    # uri = endpoint/repo:tag
# pushing to ec3 repository
docker push localhost:4510/streaming-repo:latest
# create a lambda function from ecr (get the arn of the role from the validation command above)
aws lambda create-function --function-name my-lambda-function --package-type Image --code ImageUri=localhost:4510/streaming-repo:latest --role arn:aws:iam::<aws-account-id>:role/lambda-execution-role
```

#### To test the lambda function
```bash
# create a payload event json then run this (use the payload from test_lambda)
aws lambda invoke --cli-binary-format raw-in-base64-out --function-name my-lambda-function --payload file://event.json output.json
```

#### Integration of Kinesis Stream
```bash
# create kinesis stream
aws kinesis create-stream --stream-name ride_predictions --shard-count 1
# describe kinesis stream
aws kinesis describe-stream --stream-name ride_predictions
# attaching the kinesis stream to our lambda function as input stream
aws lambda create-event-source-mapping --function-name my-lambda-function --event-source  arn:aws-cn:kinesis:us-east-1:111122223333:stream/ride_predictions --batch-size 100 --starting-position LATEST
# validation to chek ofr the status of the mapping
aws lambda list-event-source-mappings --function-name ProcessKinesisRecords --event-source arn:aws-cn:kinesis:us-east-1:111122223333:stream/ride_predictions
```

For testing, run the following command to push to kinesis
```bash
aws kinesis put-record --stream-name ride_predictions --partition-key 1 \
    --data '{
        "ride": {
            "PULocationID": 130,
            "DOLocationID": 205,
            "trip_distance": 3.66
        }, 
        "ride_id": 256
    }'
```

#### For outputing to Kinesis stream
- Create the kinesis output stream with the following command:
```bash
# create kinesis stream
aws kinesis create-stream --stream-name output-stream --shard-count 1
```

- Create policy for writing to kinesis
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kinesis:PutRecord",
        "kinesis:PutRecords"
      ],
      // grab the arn from describing the output-stream
      "Resource": "arn:aws:kinesis:<region>:<account-id>:stream/<your-stream-name>" 
    }
  ]
}
```

Run the following commnads
```bash
# create policy with kinesis-write-policy json
aws iam create-policy --policy-name LambdaKinesisWritePolicy --policy-document file://kinesis-write-policy.json
# attach policy to our lambda function
aws iam attach-role-policy --role-name lambda-kinesis-role --policy-arn arn:aws:iam::<account-id>:policy/LambdaKinesisWritePolicy
```

For testing, run the following command to listen to kinesis
```bash
KINESIS_STREAM_OUTPUT='output-stream'
SHARD='shardId-000000000000'
SHARD_ITERATOR=$(aws kinesis get-shard-iterator --shard-id ${SHARD} --shard-iterator-type TRIM_HORIZON --stream-name ${KINESIS_STREAM_OUTPUT} --query 'ShardIterator')
RESULT=$(aws kinesis get-records --shard-iterator $SHARD_ITERATOR)

echo ${RESULT} | jq -r '.Records[0].Data' | base64 --decode
```