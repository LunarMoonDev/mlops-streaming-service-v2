#!/usr/bin/env bash

cd "$(dirname "$0")"

# to prepare for logs, make it nice
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'


# prepare docker image
echo -e "${YELLOW}$(date '+%Y-%m-%d %H:%M:%S') - === Block 1: Preparing Image ===${NC}"

LOCAL_TAG=$(date +"%Y-%m-%d-%H-%M")
export LOCAL_IMAGE_NAME="stream-model-duration:${LOCAL_TAG}"
echo -e "${YELLOW}$(date '+%Y-%m-%d %H:%M:%S') - LOCAL_IMAGE_NAME is not set, building a new image with tag ${LOCAL_IMAGE_NAMES}${NC}"
docker build -f ../docker/streaming.dockerfile -t ${LOCAL_IMAGE_NAME} ..

echo -e "\n\n"

# run docker image by creating container
echo -e "${YELLOW}$(date '+%Y-%m-%d %H:%M:%S') - === Block 2: Creating Container ===${NC}"

docker compose -f local.yaml up -d

echo -e "\n\n"

# delay for container cus detached
echo -e "${BLUE}$(date '+%Y-%m-%d %H:%M:%S') - === Block 3: Delaying for 5 seconds ===${NC}"

SLEEP 5

echo -e "\n\n"

# run integration test
echo -e "${GREEN}$(date '+%Y-%m-%d %H:%M:%S') - === Block 4: Running Integration Test ===${NC}"

pipenv run python test_lambda.py
ERROR_CODE=$?
echo -e "\n\n"

# cleanup
echo -e "${YELLOW}$(date '+%Y-%m-%d %H:%M:%S') - === Block 5: Cleaning up resources ===${NC}"
if [ ${ERROR_CODE} != 0 ]; then
    echo -e "HI"
    docker compose -f local.yaml logs
    docker compose -f local.yaml down
    exit ${ERROR_CODE}
fi

docker compose -f local.yaml down