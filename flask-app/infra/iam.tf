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

# אפשרות לאחסן את ה-Access Key בצורה מאובטחת אם צריך
output "yakir_access_key_id" {
  value = aws_iam_access_key.yakir_access_key.id
}

output "yakir_secret_access_key" {
  value     = aws_iam_access_key.yakir_access_key.secret
  sensitive = true
}

