# ========== IAM ROLE FOR EKS CLUSTER ==========

resource "aws_iam_role" "eks_role" {
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

resource "aws_iam_role_policy_attachment" "eks_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ========== IAM ROLE FOR EKS NODE GROUP ==========

resource "aws_iam_role" "node_group_role" {
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

resource "aws_iam_role_policy_attachment" "node_group_worker_node_policy" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_group_cni_policy" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_group_registry_policy" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# ========== IAM USER ==========

resource "aws_iam_user" "yakir" {
  name = "yakir"
}

# ========== ADMIN-LIKE POLICY FOR USER ==========

resource "aws_iam_policy" "yakir_admin_policy" {
  name        = "yakir-admin-policy"
  description = "Policy for yakir to access AWS resources used by Terraform"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # EC2
      {
        Effect = "Allow",
        Action = [
          "ec2:*"
        ],
        Resource = "*"
      },
      # EKS
      {
        Effect = "Allow",
        Action = ["eks:*"],
        Resource = "*"
      },
      # ECR
      {
        Effect = "Allow",
        Action = [
          "ecr:*"
        ],
        Resource = "*"
      },
      # S3
      {
        Effect = "Allow",
        Action = [
          "s3:*"
        ],
        Resource = "*"
      },
      # IAM
      {
        Effect = "Allow",
        Action = [
          "iam:*"
        ],
        Resource = "*"
      },
      # CloudWatch Logs
      {
        Effect = "Allow",
        Action = [
          "logs:*"
        ],
        Resource = "*"
      }
    ]
  })
}

# ========== ATTACH POLICY TO USER ==========

resource "aws_iam_user_policy_attachment" "attach_yakir_admin_policy" {
  user       = aws_iam_user.yakir.name
  policy_arn = aws_iam_policy.yakir_admin_policy.arn
}
