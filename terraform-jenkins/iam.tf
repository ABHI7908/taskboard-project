# --- Role Jenkins's EC2 instance assumes ---
resource "aws_iam_role" "jenkins" {
  name = "jenkins-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Push/pull images to/from ECR
resource "aws_iam_role_policy_attachment" "ecr_power" {
  role       = aws_iam_role.jenkins.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# Lets you manage/debug the instance via SSM Session Manager without SSH/a key pair
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.jenkins.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Minimal permission to resolve cluster info for `aws eks update-kubeconfig`
resource "aws_iam_role_policy" "eks_describe" {
  name = "eks-describe-cluster"
  role = aws_iam_role.jenkins.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["eks:DescribeCluster", "eks:ListClusters"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_instance_profile" "jenkins" {
  name = "jenkins-ec2-profile"
  role = aws_iam_role.jenkins.name
}

# --- Grant that role kubectl access inside the cluster itself ---
# This is the EKS "access entry" API (replaces editing the aws-auth ConfigMap by hand).
resource "aws_eks_access_entry" "jenkins" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.jenkins.arn
  type          = "STANDARD"
}

# Scope: cluster-admin is simplest to get the pipeline working; narrow this
# to a custom RBAC role (e.g. edit access to one namespace) once it's running.
resource "aws_eks_access_policy_association" "jenkins" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.jenkins.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}
