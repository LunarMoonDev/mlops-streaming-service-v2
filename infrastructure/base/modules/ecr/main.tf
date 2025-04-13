resource "aws_ecr_repository" "repository" {
  name = var.ecr_repo_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  force_delete = true
}

output "repo_url" {
  value = aws_ecr_repository.repository.repository_url
}
