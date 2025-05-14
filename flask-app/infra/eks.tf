# יצירת Role עבור EKS
resource "aws_iam_role" "eks_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# חיבור Policy לרול EKS
resource "aws_iam_role_policy_attachment" "eks_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# יצירת Role עבור GitHub Actions (לגישה ל-ECR ו-EKS)
resource "aws_iam_policy" "github_actions_policy" {
  name        = "github-actions-policy"
  description = "Policy for GitHub Actions to interact with AWS services"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "eks:DescribeCluster",
          "eks:DescribeUpdate",
          "eks:UpdateClusterConfig",
          "eks:ListNodegroups",
          "eks:DescribeNodegroup",
          "eks:ListClusters"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter"
        ],
        Resource = "*"
      }
    ]
  })
}

# יצירת Role עבור GitHub Actions והחלת המדיניות
resource "aws_iam_role" "github_actions_role" {
  name = "github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action   = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_role_policy_attachment" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.github_actions_policy.arn
}

# יצירת Security Group עבור ה-EKS
resource "aws_security_group" "eks_cluster_sg" {
  name   = "eks-cluster-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# יצירת EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = "devops-cluster"
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids         = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_policy]
}

# יצירת Role עבור Node Group
resource "aws_iam_role" "node_group_role" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# חיבור Policy עבור Node Group Role
resource "aws_iam_role_policy_attachment" "node_group_policy" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# יצירת סאבנטות ציבוריות ופרטיות (אם עדיין לא הוגדרו)
resource "aws_subnet" "public" {
  count = 2
  vpc_id = aws_vpc.main.id
  cidr_block = element(var.public_subnet_cidr_blocks, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private" {
  count = 2
  vpc_id = aws_vpc.main.id
  cidr_block = element(var.private_subnet_cidr_blocks, count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
}

# יצירת VPC (אם לא הוגדר כבר)
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
}

