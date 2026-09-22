variable "region" {
  description = "AWS region — must match where taskboard-eks lives"
  type        = string
  default     = "ap-south-1"
}

variable "cluster_name" {
  description = "Existing EKS cluster to grant Jenkins access to"
  type        = string
  default     = "taskboard-eks"
}

variable "vpc_name_tag" {
  description = "Name tag of the existing taskboard VPC (from the main terraform/vpc.tf)"
  type        = string
  default     = "taskboard-vpc"
}

variable "instance_type" {
  description = "EC2 instance size for Jenkins"
  type        = string
  default     = "t3.medium"
}

variable "allowed_ui_cidr" {
  description = "CIDR allowed to reach the Jenkins UI on port 8080. Restrict this to your own IP (e.g. 1.2.3.4/32) before applying — 0.0.0.0/0 is open to the whole internet."
  type        = string
  default     = "0.0.0.0/0"
}

variable "key_name" {
  description = "Optional EC2 key pair name for SSH fallback access. Leave null to manage the instance only via SSM Session Manager (no SSH key needed)."
  type        = string
  default     = null
}
