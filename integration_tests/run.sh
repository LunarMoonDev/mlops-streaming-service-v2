#!/usr/bin/env bash

cd "$(dirname "$0")"

# to prepare for logs, make it nice
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'

NC='\033[0m'

# prepare docker image
echo -e "${YELLOW}$(date '+%Y-%m-%d %H:%M:%S') - === Block 1: Preparing Image ===${NC}"
if [ "${LOCAL_IMAGE_NAME}" == "" ]; then
    LOCAL_TAG=$(date +"%Y-%m-%d-%H-%M")
    export LOCAL_IMAGE_NAME="stream-model-kinesis-duration:${LOCAL_TAG}"
    echo -e "${YELLOW}$(date '+%Y-%m-%d %H:%M:%S') - LOCAL_IMAGE_NAME is not set, building a new image with tag ${LOCAL_IMAGE_NAME}${NC}"
    docker build -f ../docker/streaming.dockerfile -t ${LOCAL_IMAGE_NAME} ..
else
    echo -e "${YELLOW}$(date '+%Y-%m-%d %H:%M:%S') - LOCAL_IMAGE_NAME is already set, using tag ${LOCAL_IMAGE_NAME}${NC}"
fi
echo -e "\n\n"

# run docker image by creating container
echo -e "${YELLOW}$(date '+%Y-%m-%d %H:%M:%S') - === Block 2: Creating Container ===${NC}"
docker compose -f kinesis.yaml up -d
echo -e "\n\n"

# delay for container cus detached
echo -e "${BLUE}$(date '+%Y-%m-%d %H:%M:%S') - === Block 3: Delaying for 10 seconds ===${NC}"
sleep 10
echo -e "\n\n"

# create aws kinesis stream for output
echo -e "${MAGENTA}$(date '+%Y-%m-%d %H:%M:%S') - === Block 4: Creating AWS Kinesis stream ===${NC}"
export AWS_PROFILE=localstack
export AWS_PAGER=""
# need this because gitbash is screwing with the parameter name (VERY WEIRD)
export MSYS2_ARG_CONV_EXCL="*"
aws kinesis create-stream \
    --stream-name output_streams \
    --shard-count 1
    # --debug
echo -e "\n\n"

# create aws kinesis stream for output
echo -e "${MAGENTA}$(date '+%Y-%m-%d %H:%M:%S') - === Block 5: Preparing AWS Parameter Store ===${NC}"
aws ssm put-parameter --name "/streaming/config/prediction_stream_name" --value "output_streams" --type "SecureString"
aws ssm put-parameter --name "/streaming/config/run_id" --value "IntegrationTestRunID" --type "SecureString"
aws ssm put-parameter --name "/streaming/config/debug" --value "false" --type "SecureString"
echo -e "\n\n"

# run integration test
echo -e "${GREEN}$(date '+%Y-%m-%d %H:%M:%S') - === Block 6: Running Integration Test ===${NC}"

#  running lambda integration test
pipenv run python test_lambda.py
ERROR_CODE=$?
echo -e "\n\n"

# cleanup
if [ ${ERROR_CODE} != 0 ]; then
    echo -e "${YELLOW}$(date '+%Y-%m-%d %H:%M:%S') - === Block 7: Cleaning up resources ===${NC}"
    docker compose -f kinesis.yaml logs
    docker compose -f kinesis.yaml down
    exit ${ERROR_CODE}
fi

#  running kinesis integration test
pipenv run python test_kinesis.py
ERROR_CODE=$?
echo -e "\n\n"

# cleanup
if [ ${ERROR_CODE} != 0 ]; then
    echo -e "${YELLOW}$(date '+%Y-%m-%d %H:%M:%S') - === Block 7: Cleaning up resources ===${NC}"
    docker compose -f kinesis.yaml logs
    docker compose -f kinesis.yaml down
    exit ${ERROR_CODE}
fi

echo -e "${YELLOW}$(date '+%Y-%m-%d %H:%M:%S') - === Block 8: Cleaning up resources ===${NC}"
docker compose -f kinesis.yaml down
