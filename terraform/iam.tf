resource "aws_iam_role" "jenkins_ecr_push" {
  name = "jenkins-ecr-push-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_power" {
  role       = aws_iam_role.jenkins_ecr_push.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

output "jenkins_role_arn" {
  value = aws_iam_role.jenkins_ecr_push.arn
}
