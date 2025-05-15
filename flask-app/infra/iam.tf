# יצירת מדיניות IAM עבור גישה רק ל-EKS, Node Group, S3 ו-ECR
resource "aws_iam_policy" "yakir_project_policy" {
  name        = "yakir-project-policy"
  description = "Policy to allow yakir to manage specific resources for the Terraform project"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # הרשאות לגישה ל-EKS Cluster
      {
        Effect   = "Allow"
        Action   = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:UpdateClusterVersion",
          "eks:CreateCluster",
          "eks:DeleteCluster"
        ]
        Resource = "*"
      },
      # הרשאות עבור Node Group של EKS
      {
        Effect   = "Allow"
        Action   = [
          "eks:CreateNodegroup",
          "eks:UpdateNodegroupConfig",
          "eks:DeleteNodegroup",
          "eks:DescribeNodegroup"
        ]
        Resource = "*"
      },
      # הרשאות גישה ל-S3 עבור Terraform state
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::terraform-state-bucketxyz123/*"
      },
      # הרשאות גישה ל-ECR לדחיפת ודפיסת תמונות Docker
      {
        Effect   = "Allow"
        Action   = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetAuthorizationToken",
          "ecr:PutImage",
          "ecr:BatchGetImage"
        ]
        Resource = "arn:aws:ecr:us-east-2:***:repository/flask-app-repo"
      },
      # הרשאות קריאה וכתיבה על EC2 עבור Node Group
      {
        Effect   = "Allow"
        Action   = [
          "ec2:DescribeInstances",
          "ec2:CreateSecurityGroup",
          "ec2:DescribeSecurityGroups",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateSecurityGroupRule",
          "ec2:ModifyInstanceAttribute"
        ]
        Resource = "*"
      }
    ]
  })
}

# יצירת משתמש IAM בשם yakir
resource "aws_iam_user" "yakir" {
  name = "yakir"
}

# חיבור המדיניות למשתמש yakir
resource "aws_iam_user_policy_attachment" "attach_yakir_project_policy" {
  user       = aws_iam_user.yakir.name
  policy_arn = aws_iam_policy.yakir_project_policy.arn
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

