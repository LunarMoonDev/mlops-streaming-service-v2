# global variables
LOCAL_TAG:=$(shell date +"%Y-%m-%d-%H-%M")
LOCAL_IMAGE_NAME:=stream-model-duration:${LOCAL_TAG}

# for pretty logs
GREEN	:= \033[0;32m
BLUE    := \033[0;34m
RESET   := \033[0m

# function in makefile
echo_message = \
	@echo -e "$(BLUE)************************************************************************" \
	 " $(GREEN)[$(shell date +'%Y-%m-%d %H:%M:%S')] $1 " \
	 "$(BLUE)************************************************************************$(RESET) \n"

# targets
test:
	$(call echo_message,[TEST] Starting installation...)
	pytest tests/

quality_checks:
	$(call echo_message,[QUALITY_CHECK] Starting quality check...)
	isort .
	black .
	pylint --recursive=y .

build: quality_checks test
	$(call echo_message,[BUILD] Building docker image...)
	docker build -f docker/streaming.dockerfile -t ${LOCAL_IMAGE_NAME} .
	@echo "[BUILD-STAGE] docker image build complete!!!"

integration_test: build
	$(call echo_message,[INTEGRATION_TEST] Starting integration test...)
	LOCAL_IMAGE_NAME=${LOCAL_IMAGE_NAME} bash integration_tests/run.sh

setup:
	$(call echo_message,[SETUP] Setting up development environment...)
	pipenv install --dev
	pre-commit install
