resource "aws_iam_policy" "yakir_admin_policy" {
  name        = "yakir-admin-policy"
  description = "Policy for yakir to access AWS resources used by Terraform"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:Describe*",
          "ec2:Create*",
          "ec2:Delete*",
          "ec2:Attach*",
          "ec2:Detach*",
          "ec2:AllocateAddress",
          "ec2:AssociateAddress",
          "ec2:DisassociateAddress",
          "ec2:ReleaseAddress"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "eks:*"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:CreateBucket"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
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
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "attach_yakir_admin_policy" {
  user       = "yakir"
  policy_arn = aws_iam_policy.yakir_admin_policy.arn
}

resource "aws_iam_policy" "terraform_s3_access_policy" {
  name        = "terraform-s3-access-policy"
  description = "Policy to allow Terraform access to S3 state files"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::terraform-state-bucketxyz123",
          "arn:aws:s3:::terraform-state-bucketxyz123/*"
        ]
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "terraform_s3_policy_attachment" {
  user       = "yakir"  # או את המשתמש הנכון
  policy_arn = aws_iam_policy.terraform_s3_access_policy.arn
}

resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = "terraform-state-bucketxyz123"
}

resource "aws_s3_bucket_object" "terraform_state_file" {
  bucket = aws_s3_bucket.terraform_state_bucket.bucket
  key    = "terraform/terraform.tfstate"
  source = "path/to/local/terraform.tfstate"  # אם יש לך קובץ tfstate מקומי שאתה רוצה להעלות
  acl    = "private"
}

resource "aws_s3_bucket_object_acl" "allow_terraform_state_access" {
  bucket = aws_s3_bucket.terraform_state_bucket.bucket
  key    = "terraform/terraform.tfstate"
  acl    = "private"
}

resource "aws_s3_bucket_policy" "terraform_state_bucket_policy" {
  bucket = aws_s3_bucket.terraform_state_bucket.bucket

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = [
          "arn:aws:s3:::terraform-state-bucketxyz123",
          "arn:aws:s3:::terraform-state-bucketxyz123/*"
        ],
        Principal = "*"
      }
    ]
  })
}

