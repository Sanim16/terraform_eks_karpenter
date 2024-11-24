# Create VPC using a module
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs              = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets   = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  database_subnets = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]
  intra_subnets    = ["10.0.207.0/24", "10.0.208.0/24", "10.0.209.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  enable_dns_hostnames   = true
  one_nat_gateway_per_az = false

  map_public_ip_on_launch = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Name        = var.vpc_name
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    # Tags subnets for Karpenter auto-discovery
    "karpenter.sh/discovery" = var.cluster_name
  }
}

resource "aws_security_group" "terraform-dev-vpc" {
  name        = "terraform-${var.vpc_name}"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-${var.vpc_name}"
    "karpenter.sh/discovery" = var.cluster_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "terraform-dev-vpc-ssh" {
  security_group_id = aws_security_group.terraform-dev-vpc.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}

resource "aws_vpc_security_group_ingress_rule" "terraform-dev-vpc-http" {
  security_group_id = aws_security_group.terraform-dev-vpc.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
}

resource "aws_vpc_security_group_ingress_rule" "terraform-dev-vpc-https" {
  security_group_id = aws_security_group.terraform-dev-vpc.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  ip_protocol = "tcp"
  to_port     = 443
}
