terraform {
  required_version = ">= 1.0"
  backend "s3" {
    bucket = "tf-state-mlops-zoomcamp"
    key = "mlops-zoomcamp-main-stg.tfstate"
    region = "eu-west-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current_identity" {

}
data "mlops_zoomcamp_base" "base_repo" {
    backend = "s3"
    config = {
        bucket = "tf-state-mlops-zoomcamp"
        key = "mlops-zoomcamp-base-stg.tfstate"
        region = "eu-west-1"
    }
}

locals {
  account_id = data.aws_caller_identity.current_identity.account_id
}

module "name" {
  source = "./modules/lambda"
  image_uri = "${data.mlops_zoomcamp_base.base_repo.outputs.ecr_repo_url}:${var.image_tag}"
  lambda_function_name = "${var.lambda_function_name}_${var.project_id}"
  model_bucket = data.mlops_zoomcamp_base.base_repo.outputs.s3_bucket_name
  output_stream_arn = data.mlops_zoomcamp_base.base_repo.outputs.output_stream_arn
  source_stream_arn = data.mlops_zoomcamp_base.base_repo.outputs.source_stream_arn
}
