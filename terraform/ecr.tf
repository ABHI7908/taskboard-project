resource "aws_ecr_repository" "taskboard" {
  name                 = "taskboard"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

output "ecr_repository_url" {
  value = aws_ecr_repository.taskboard.repository_url
}
