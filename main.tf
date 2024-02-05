data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "role" {
  name               = "eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.role.name
}
#get default vpc data
data "aws_vpc" "default" {
    default = true
}
#get public subnets for cluster
data "aws_subnets" "public" {
    filter {
      name = "vpc-id"
      values = [ data.aws_vpc.default.id ]
    }
}
#cluster provision
resource "aws_eks_cluster" "eks_cluster" {
  name     = "First-cluster"
  role_arn = aws_iam_role.role.arn

  vpc_config {
    subnet_ids = data.aws_subnets.public.ids
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.example-AmazonEKSClusterPolicy
  ]
}
