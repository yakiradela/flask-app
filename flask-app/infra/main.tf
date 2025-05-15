provider "aws" {
  region = var.region
}

# ================= VPC =================
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "devops-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}

resource "aws_eip" "nat_eip" {
  count  = 2
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  count         = 2
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  depends_on = [aws_internet_gateway.igw]
}

# ================= Route Tables =================
resource "aws_route_table" "public_rt" {
  count  = 2
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_rt[count.index].id
}

resource "aws_route_table" "private_rt" {
  count  = 2
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }
}

resource "aws_route_table_association" "private_assoc" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_rt[count.index].id
}

# ================= EKS Cluster =================
resource "aws_eks_cluster" "main" {
  name     = "my-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn  # Correct reference to IAM role

  vpc_config {
    subnet_ids = [aws_subnet.public[0].id, aws_subnet.public[1].id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.attach_eks_cluster_policy  # Correct reference to policy attachment
  ]
}

# ================= EKS Node Group =================
resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "flask-node-group"
  node_role_arn   = aws_iam_role.node_group_role.arn
  subnet_ids      = aws_subnet.private[*].id

  scaling_config {
    desired_size = var.node_group_desired_size
    max_size     = 3
    min_size     = 1
  }

  instance_types = [var.node_group_instance_type]

  depends_on = [
    aws_eks_cluster.main,
    aws_iam_role_policy_attachment.node_group_worker_node_policy,
    aws_iam_role_policy_attachment.node_group_cni_policy,
    aws_iam_role_policy_attachment.node_group_registry_policy
  ]
}

