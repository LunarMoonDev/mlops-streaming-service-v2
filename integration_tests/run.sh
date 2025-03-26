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

LOCAL_TAG=$(date +"%Y-%m-%d-%H-%M")
export LOCAL_IMAGE_NAME="stream-model-kinesis-duration:${LOCAL_TAG}"
echo -e "${YELLOW}$(date '+%Y-%m-%d %H:%M:%S') - LOCAL_IMAGE_NAME is not set, building a new image with tag ${LOCAL_IMAGE_NAMES}${NC}"
docker build -f ../docker/streaming.dockerfile -t ${LOCAL_IMAGE_NAME} ..

echo -e "\n\n"

# run docker image by creating container
echo -e "${YELLOW}$(date '+%Y-%m-%d %H:%M:%S') - === Block 2: Creating Container ===${NC}"

docker compose -f kinesis.yaml up -d

echo -e "\n\n"

# delay for container cus detached
echo -e "${BLUE}$(date '+%Y-%m-%d %H:%M:%S') - === Block 3: Delaying for 5 seconds ===${NC}"

sleep 5

echo -e "\n\n"

# create aws kinesis stream for output
echo -e "${MAGENTA}$(date '+%Y-%m-%d %H:%M:%S') - === Block 4: Creating AWS Kinesis stream ===${NC}"
export AWS_PROFILE=localstack
aws kinesis create-stream \
    --stream-name output_streams \
    --shard-count 1
    # --debug

echo -e "\n\n"

# run integration test
echo -e "${GREEN}$(date '+%Y-%m-%d %H:%M:%S') - === Block 5: Running Integration Test ===${NC}"

#  running lambda integration test
pipenv run python test_lambda.py
ERROR_CODE=$?
echo -e "\n\n"

# cleanup
if [ ${ERROR_CODE} != 0 ]; then
    echo -e "${YELLOW}$(date '+%Y-%m-%d %H:%M:%S') - === Block 6: Cleaning up resources ===${NC}"
    echo -e "HI"
    docker compose -f local.yaml logs
    docker compose -f local.yaml down
    exit ${ERROR_CODE}
fi

#  running kinesis integration test
pipenv run python test_kinesis.py
ERROR_CODE=$?
echo -e "\n\n"

# cleanup
if [ ${ERROR_CODE} != 0 ]; then
    echo -e "${YELLOW}$(date '+%Y-%m-%d %H:%M:%S') - === Block 6: Cleaning up resources ===${NC}"
    echo -e "HI"
    docker compose -f kinesis.yaml logs
    docker compose -f kinesis.yaml down
    exit ${ERROR_CODE}
fi

echo -e "${YELLOW}$(date '+%Y-%m-%d %H:%M:%S') - === Block 6: Cleaning up resources ===${NC}"
docker compose -f kinesis.yaml down
