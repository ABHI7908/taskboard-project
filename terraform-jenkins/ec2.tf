resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.public.ids[0]
  vpc_security_group_ids      = [aws_security_group.jenkins.id]
  iam_instance_profile        = aws_iam_instance_profile.jenkins.name
  associate_public_ip_address = true
  key_name                    = var.key_name

  user_data                   = file("${path.module}/user_data.sh")
  user_data_replace_on_change = true

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name    = "jenkins-server"
    Project = "taskboard"
  }
}
