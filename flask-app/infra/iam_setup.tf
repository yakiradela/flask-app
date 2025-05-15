resource "aws_iam_user" "yakir" {
  name = "yakir"
}

resource "aws_iam_policy" "yakir_admin_policy" {
  name        = "yakir-admin-policy"
  description = "Full permissions for yakir to manage AWS infrastructure using Terraform"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["ec2:*", "s3:*", "iam:*", "eks:*", "ecr:*", "logs:*", "sts:AssumeRole"],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "attach_yakir_admin_policy" {
  user       = aws_iam_user.yakir.name
  policy_arn = aws_iam_policy.yakir_admin_policy.arn
}

resource "aws_iam_access_key" "yakir_access_key" {
  user = aws_iam_user.yakir.name
}

