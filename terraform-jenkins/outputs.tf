output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "jenkins_url" {
  value = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "jenkins_instance_id" {
  value = aws_instance.jenkins.id
}

output "jenkins_iam_role_arn" {
  value = aws_iam_role.jenkins.arn
}
