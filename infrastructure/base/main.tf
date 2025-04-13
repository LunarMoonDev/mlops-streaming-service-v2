terraform {
    required_version = ">= 1.0"
    backend "s3" {
      bucket = "tf-state-mlops-zoomcamp"
      key = "mlops-zoomcamp-base-stg.tfstate"
      region = "eu-west-1"
      encrypt = true
    }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current_identity" {}

locals {
  account_id = data.aws_caller_identity.current_identity.account_id
}

module "source_kinesis_stream" {
  source = "./modules/kinesis"
  retention_period = 48
  shard_count = 2
  stream_name = "${var.source_stream_name}-${var.project_id}"
  tags = var.project_id
}

module "output_kinesis_stream" {
  source = "./modules/kinesis"
  retention_period = 48
  shard_count = 2
  stream_name = "${var.output_stream_name}-${var.project_id}"
  tags = var.project_id
}

module "s3_bucket" {
  source = "./modules/s3"
  bucket_name = "${var.model_bucket}-${var.project_id}"
}

module "ecr_repository" {
  source = "./modules/ecr"
  ecr_repo_name = "${var.ecr_repo_name}_${var.project_id}"
}

output "ecr_repo_url" {
  value = module.ecr_repository.repo_url
}

output "s3_bucket_name" {
  value = module.s3_bucket.name
}

output "output_stream_arn" {
  value = module.output_kinesis_stream.stream_arn
}

output "source_stream_arn" {
  value = module.source_kinesis_stream.stream_arn
}
