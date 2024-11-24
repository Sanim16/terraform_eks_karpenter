terraform {
  ############################################################
  # AFTER RUNNING TERRAFORM APPLY (WITH LOCAL BACKEND)
  # YOU WILL UNCOMMENT THIS CODE THEN RERUN TERRAFORM INIT
  # TO SWITCH FROM LOCAL BACKEND TO REMOTE AWS BACKEND
  ############################################################
  backend "s3" {
    bucket         = "unique-bucket-name-msctf" # REPLACE WITH YOUR BUCKET NAME
    key            = "remote-backend/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.75"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.7"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}

# provider "kubectl" {
#   host                   = module.eks.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
#   token                  = data.aws_eks_cluster_auth.cluster.token
# }

# data "aws_eks_cluster" "cluster" {
#   name       = module.eks.cluster_name
#   depends_on = [module.eks]
# }

# data "aws_eks_cluster_auth" "cluster" {
#   name = module.eks.cluster_name
#   depends_on = [
#     data.aws_eks_cluster.cluster
#   ]
# }

# provider "helm" {
#   kubernetes {
#     host                   = module.eks.cluster_endpoint
#     cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
#     token                  = data.aws_eks_cluster_auth.cluster.token
#   }
# }

# data "aws_ecrpublic_authorization_token" "token" {}
