region = "us-east-2"
azs    = ["us-east-2a", "us-east-2b"]

vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]

node_group_desired_size   = 2
node_group_instance_type  = "t3.medium"

