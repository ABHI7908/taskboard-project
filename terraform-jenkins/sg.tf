resource "aws_security_group" "jenkins" {
  name        = "jenkins-sg"
  description = "Jenkins UI + agent ports"
  vpc_id      = data.aws_vpc.taskboard.id

  ingress {
    description = "Jenkins web UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ui_cidr]
  }

  # Only needed if you attach remote build agents later
  ingress {
    description = "Jenkins agent JNLP port"
    from_port   = 50000
    to_port     = 50000
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.taskboard.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "jenkins-sg" }
}
