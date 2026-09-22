# Reuses the VPC created by ../terraform (main infra) — doesn't recreate networking.

data "aws_vpc" "taskboard" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name_tag]
  }
}

# Public subnets were tagged kubernetes.io/role/elb = "1" in ../terraform/vpc.tf
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.taskboard.id]
  }

  tags = {
    "kubernetes.io/role/elb" = "1"
  }
}

data "aws_eks_cluster" "taskboard" {
  name = var.cluster_name
}

# Latest Ubuntu 22.04 LTS AMI (Canonical's official account)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
