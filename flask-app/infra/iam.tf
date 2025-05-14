# ========== IAM ROLE FOR EKS CLUSTER ==========

resource "aws_iam_role" "eks_role" {
  name = "eks-cluster-role"

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

resource "aws_iam_role_policy_attachment" "eks_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ========== IAM POLICY FOR USER yakir ==========

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

# ========== IAM POLICY FOR S3 STATE ACCESS ==========

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
  user       = "yakir"
  policy_arn = aws_iam_policy.terraform_s3_access_policy.arn
}

# ========== S3 BUCKET FOR STATE FILES ==========

resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = "terraform-state-bucketxyz123"
}

resource "aws_s3_bucket_object" "terraform_state_file" {
  bucket = aws_s3_bucket.terraform_state_bucket.bucket
  key    = "terraform/terraform.tfstate"
  source = "path/to/local/terraform.tfstate"
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

# ========== EKS CLUSTER AND NODE GROUPS ==========

resource "aws_iam_role" "node_group_role" {
  name = "eks-node-group-role"

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

resource "aws_eks_cluster" "main" {
  name     = "devops-cluster"
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids         = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_policy]
}

resource "aws_eks_node_group" "private_nodes" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "private-node-group"
  node_role_arn   = aws_iam_role.node_group_role.arn
  subnet_ids      = aws_subnet.private[*].id

  scaling_config {
    desired_size = var.node_group_desired_size
    max_size     = 3
    min_size     = 1
  }

  instance_types = [var.node_group_instance_type]
}

resource "aws_eks_node_group" "public_nodes" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "public-node-group"
  node_role_arn   = aws_iam_role.node_group_role.arn
  subnet_ids      = aws_subnet.public[*].id

  scaling_config {
    desired_size = var.node_group_desired_size
    max_size     = 3
    min_size     = 1
  }

  instance_types = [var.node_group_instance_type]
}
{
  "Effect": "Allow",
  "Action": [
    "s3:ListBucket",
    "s3:GetObject",
    "s3:PutObject",
    "s3:DeleteObject"
  ],
  "Resource": [
    "arn:aws:s3:::terraform-state-bucketxyz123",
    "arn:aws:s3:::terraform-state-bucketxyz123/*"
  ]
}


