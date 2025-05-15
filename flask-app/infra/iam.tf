# יצירת מדיניות IAM עם כל ההרשאות הנדרשות
resource "aws_iam_policy" "yakir_admin_policy" {
  name        = "yakir-admin-policy"
  description = "Full permissions for yakir to manage AWS infrastructure using Terraform"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # EC2
      {
        Effect   = "Allow"
        Action   = ["ec2:*"]
        Resource = "*"
      },
      # S3
      {
        Effect   = "Allow"
        Action   = ["s3:*"]
        Resource = "*"
      },
      # IAM
      {
        Effect   = "Allow"
        Action   = ["iam:*"]
        Resource = "*"
      },
      # EKS
      {
        Effect   = "Allow"
        Action   = ["eks:*"]
        Resource = "*"
      },
      # ECR
      {
        Effect   = "Allow"
        Action   = ["ecr:*"]
        Resource = "*"
      },
      # CloudWatch Logs
      {
        Effect   = "Allow"
        Action   = ["logs:*"]
        Resource = "*"
      },
      # STS
      {
        Effect   = "Allow"
        Action   = ["sts:AssumeRole"]
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

# יצירת Access Key עבור המשתמש yakir
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
resource "aws_iam_role" "node_group_role" {
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
resource "aws_iam_role_policy_attachment" "eks_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# חיבור מדיניות לתפקיד Node Group: Worker Node
resource "aws_iam_role_policy_attachment" "node_group_worker_node_policy" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# חיבור מדיניות לתפקיד Node Group: CNI
resource "aws_iam_role_policy_attachment" "node_group_cni_policy" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# חיבור מדיניות לתפקיד Node Group: ECR Registry Access
resource "aws_iam_role_policy_attachment" "node_group_registry_policy" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# יצירת מדיניות IAM עבור המשתמש כדי לאפשר לו יצירת משתמשים ומדיניות
resource "aws_iam_policy" "admin_policy" {
  name        = "admin-policy"
  description = "Admin policy for creating IAM users and policies"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "iam:CreateUser",
          "iam:CreatePolicy",
          "iam:AttachUserPolicy",
          "iam:PutUserPolicy",
          "iam:DeleteUser"
        ]
        Resource = "*"
      }
    ]
  })
}

# חיבור מדיניות יצירת משתמשים ומדיניות למשתמש yakir
resource "aws_iam_user_policy_attachment" "attach_admin_policy" {
  user       = aws_iam_user.yakir.name
  policy_arn = aws_iam_policy.admin_policy.arn
}



