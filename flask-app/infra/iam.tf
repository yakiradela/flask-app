# יצירת מדיניות IAM עם כל ההרשאות הנדרשות
resource "aws_iam_policy" "yakir_admin_policy" {
  name        = "yakir-admin-policy"
  description = "Policy for yakir to access AWS resources used by Terraform"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # הרשאות EC2
      {
        Action   = [
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs",
          "ec2:DescribeAddresses",
          "ec2:DescribeInstances",
          "ec2:DescribeKeyPairs",
          "ec2:DescribeSubnets",
          "ec2:DescribeNetworkInterfaces"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      # הרשאות EKS
      {
        Action   = [
          "eks:DescribeCluster",
          "eks:DescribeNodegroup",
          "eks:ListClusters",
          "eks:CreateNodegroup"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      # הרשאות S3
      {
        Action   = [
          "s3:GetBucketVersioning",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      # הרשאות ECR
      {
        Action   = [
          "ecr:DescribeRepositories",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      # הרשאות IAM
      {
        Action   = [
          "iam:GetUser",
          "iam:GetRole",
          "iam:CreateRole",
          "iam:PassRole",
          "iam:AttachRolePolicy",
          "iam:PutRolePolicy",
          "iam:ListRoles",
          "iam:ListAttachedRolePolicies",
          "iam:CreatePolicy",
          "iam:AttachUserPolicy"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      # הרשאות CloudWatch Logs
      {
        Action   = ["logs:*"]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# יצירת משתמש IAM בשם yakir
resource "aws_iam_user" "yakir" {
  name = "yakir"
}

# חיבור המדיניות למשתמש
resource "aws_iam_user_policy_attachment" "attach_yakir_admin_policy" {
  user       = aws_iam_user.yakir.name
  policy_arn = aws_iam_policy.yakir_admin_policy.arn
}

# יצירת את ה-Access Key עבור המשתמש yakir
resource "aws_iam_access_key" "yakir_access_key" {
  user = aws_iam_user.yakir.name
}

# יצירת תפקיד IAM עבור EKS Cluster
resource "aws_iam_role" "eks_role" {
  name               = "eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

# יצירת תפקיד IAM עבור Node Group ב-EKS
resource "aws_iam_role" "node_group_role" {
  name               = "eks-node-group-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# יצירת חיבור מדיניות IAM לתפקיד ה-EKS Cluster Role
resource "aws_iam_role_policy_attachment" "eks_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# יצירת חיבור מדיניות IAM לתפקיד ה-Node Group Role
resource "aws_iam_role_policy_attachment" "node_group_policy" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_group_cni_policy" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_group_registry_policy" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_policy" "yakir_admin_policy" {
  name        = "yakir-admin-policy"
  description = "Full permissions for yakir to manage AWS infrastructure using Terraform"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # EC2
      {
        Effect   = "Allow"
        Action   = [
          "ec2:*"
        ]
        Resource = "*"
      },
      # S3
      {
        Effect   = "Allow"
        Action   = [
          "s3:*"
        ]
        Resource = "*"
      },
      # IAM
      {
        Effect   = "Allow"
        Action   = [
          "iam:*"
        ]
        Resource = "*"
      },
      # EKS
      {
        Effect   = "Allow"
        Action   = [
          "eks:*"
        ]
        Resource = "*"
      },
      # ECR
      {
        Effect   = "Allow"
        Action   = [
          "ecr:*"
        ]
        Resource = "*"
      },
      # CloudWatch Logs
      {
        Effect   = "Allow"
        Action   = [
          "logs:*"
        ]
        Resource = "*"
      },
      # STS (עבור AssumeRole)
      {
        Effect   = "Allow"
        Action   = [
          "sts:AssumeRole"
        ]
        Resource = "*"
      }
    ]
  })
}
