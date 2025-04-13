variable "aws_region" {
  description = "AWS region to create resources"
  default = "eu-west-1"
}

variable "lambda_function_name" {
  description = "function name of lambda"
}

variable "project_id" {
  description = "project_id"
  default = "mlops-zoomcamp"
}

variable "image_tag" {
  description = "tag of image to use for lambda"
}
