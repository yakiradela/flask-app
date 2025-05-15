###################################
# Data source for existing user
###################################
data "aws_iam_user" "yakir" {
  user_name = "yakir"
}

###################################
# IAM Policy for yakir
###################################
resource "aws_iam_policy" "yakir_project_policy" {
  name        = "yakir-project-policy"
  description = "Policy to allow yakir to manage EKS, EC2, Node Groups, ECR, and S3 for Terraform"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      # EKS Cluster & Node Groups
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:UpdateClusterVersion",
          "eks:CreateCluster",
          "eks:DeleteCluster",
          "eks:DescribeNodegroup",
          "eks:CreateNodegroup",
          "eks:UpdateNodegroupConfig",
          "eks:DeleteNodegroup"
        ]
        Resource = "*"
      },

      # EC2 for EKS Node Groups
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:CreateSecurityGroup",
          "ec2:DescribeSecurityGroups",
          "ec2:CreateLaunchTemplate",
          "ec2:RunInstances",
          "ec2:CreateTags",
          "ec2:AuthorizeSecurityGroupIngress"
        ]
        Resource = "*"
      },

      # PassRole permissions
      {
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:PassRole"
        ]
        Resource = "*"
      },

      # ECR permissions
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:PutImage",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },

      # S3 bucket access for Terraform state
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::terraform-state-bucketxyz123"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::terraform-state-bucketxyz123/*"
      }
    ]
  })
}

# Attach policy to yakir
resource "aws_iam_user_policy_attachment" "attach_yakir_policy" {
  user       = data.aws_iam_user.yakir.user_name
  policy_arn = aws_iam_policy.yakir_project_policy.arn
}

###################################
# EKS Cluster Role
###################################
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "eks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

###################################
# EKS Node Group Role
###################################
resource "aws_iam_role" "eks_node_group_role" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_worker_node_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "attach_cni_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "attach_ecr_read_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

###################################
# Terraform S3 Policy (attached to Node Group if needed)
###################################
resource "aws_iam_policy" "terraform_s3_policy" {
  name        = "terraform-s3-policy"
  description = "Policy for accessing Terraform state bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket"
        ],
        Resource = "arn:aws:s3:::terraform-state-bucketxyz123"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        Resource = "arn:aws:s3:::terraform-state-bucketxyz123/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_terraform_s3_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = aws_iam_policy.terraform_s3_policy.arn
}
