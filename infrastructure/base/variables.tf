variable "aws_region" {
  description = "AWS region to create resources"
  default = "eu-west-1"
}

variable "source_stream_name" {
  description = "Input stream of lambda"
}

variable "project_id" {
  description = "Id of project"
  default = "mlops-zoomcamp"
}

variable "output_stream_name" {
  description = "Output stream of lambda"
}

variable "model_bucket" {
  description = "bucket of models from mlflow"
}

variable "ecr_repo_name" {
  description = "name of ecr repository"
}
