terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.28"
    }
  }
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

locals {
  cluster_name = "eks-${random_string.suffix.result}"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.66.0"

  name                 = var.vpc_name
  cidr                 = "10.0.0.0/16"
  azs                  = var.vpc_azs
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = module.vpc.vpc_id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_subnet" "db" {
  vpc_id     = module.vpc.vpc_id
  cidr_block = "10.0.7.0/24"
}

resource "aws_db_subnet_group" "default" {
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "DB subnet group"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id     = module.vpc.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.s3"
}

resource "aws_db_instance" "default" {
  allocated_storage    = var.db_instance_allocated_storage
  max_allocated_storage = var.db_instance_max_storage
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "12.5"
  instance_class       = var.db_instance_class
  name                 = "datashop_db"
  username             = "datashop"
  password             = var.postgres_password
  multi_az             = "false"
  db_subnet_group_name = aws_db_subnet_group.default.name
  skip_final_snapshot = true
}

resource "aws_s3_bucket" "slices" {
  bucket = var.s3_bucket_name
  acl    = "private"

  tags = {
    Name        = "Datashop bucket"
  }
}

resource "aws_iam_user" "datashop-app" {
  name = "datashop-app-${random_string.suffix.result}"

  tags = {
    managed-by = "terraform"
  }
}


resource "aws_iam_access_key" "datashop-app" {
  user = aws_iam_user.datashop-app.name
}

resource "aws_iam_user_policy" "datashop-app-po" {
  name = "datashop-app-policy"
  user = aws_iam_user.datashop-app.name
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketLocation",
                "s3:ListAllMyBuckets"
            ],
            "Resource": "arn:aws:s3:::*"
        },
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::${var.s3_bucket_name}",
                "arn:aws:s3:::${var.s3_bucket_name}/*"
            ]
        }
    ]
}
EOF

}
