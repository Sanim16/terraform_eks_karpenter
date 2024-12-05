output "intra_subnet_ids" {
  value       = module.vpc.intra_subnets
  description = "private subnet ids"
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnets
  description = "public subnet ids"
}

output "private_subnet_ids" {
  value       = module.vpc.private_subnets
  description = "private subnet ids"
}

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "The VPC ID"
}

# output "security_group_id" {
#   value       = aws_security_group.terraform-dev-vpc.id
#   description = "The security group ID"
# }

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "kms_key_arn" {
  description = "The Amazon Resource Name (ARN) of the key"
  value       = module.kms.key_arn
}

output "kms_key_id" {
  description = "The globally unique identifier for the key"
  value       = module.kms.key_id
}

# output "nginx_endpoint" {
#   value = "http://${data.kubernetes_service.nginx.status.0.load_balancer.0.ingress.0.hostname}"
# }
