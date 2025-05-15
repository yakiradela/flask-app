provider "aws" {
  region = "us-east-2"
}

# שליפת המשתמש הקיים yakir
data "aws_iam_user" "yakir" {
  user_name = "yakir"
}

# מדיניות מתוקנת עם כל ההרשאות הדרושות לפרויקט
resource "aws_iam_policy" "yakir_project_policy" {
  name        = "yakir-project-policy"
  description = "Policy to allow yakir to manage EKS, EC2, Node Groups, ECR, and S3 for Terraform"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # EKS Cluster
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
      # EC2 for Node Group
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
      # IAM PassRole (נדרש להפעלת Node Group ו-EKS)
      {
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:PassRole"
        ]
        Resource = "*"
      },
      # ECR
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
      # S3 – Terraform state
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::terraform-state-bucketxyz123",
          "arn:aws:s3:::terraform-state-bucketxyz123/*"
        ]
      }
    ]
  })
}

# חיבור המדיניות למשתמש yakir
resource "aws_iam_user_policy_attachment" "attach_yakir_policy" {
  user       = data.aws_iam_user.yakir.user_name
  policy_arn = aws_iam_policy.yakir_project_policy.arn
}

# יצירת תפקיד IAM עבור EKS Cluster
resource "aws_iam_role" "eks_cluster_role" {
  name               = "eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# יצירת תפקיד IAM עבור Node Group
resource "aws_iam_role" "eks_node_group_role" {
  name               = "eks-node-group-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# חיבור מדיניות לתפקיד EKS Cluster
resource "aws_iam_role_policy_attachment" "attach_eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# חיבור מדיניות לתפקיד Node Group – Worker Node
resource "aws_iam_role_policy_attachment" "attach_worker_node_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# חיבור מדיניות לתפקיד Node Group – CNI
resource "aws_iam_role_policy_attachment" "attach_cni_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# חיבור מדיניות לתפקיד Node Group – ECR read access
resource "aws_iam_role_policy_attachment" "attach_ecr_read_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
