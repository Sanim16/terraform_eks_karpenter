variable "region" {
  default = "us-east-1"
}

variable "cluster_name" {
  description = "The name of the cluster"
  default     = "dev-cluster"
}

variable "cluster_version" {
  description = "The version of the cluster"
  default     = "1.30"
}

variable "vpc_name" {
  description = "The name of the vpc"
  default     = "dev-vpc"
}

variable "vpc_cidr" {
  type        = string
  description = "cidr block for the vpc"
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  type        = string
  description = "cidr block for the subnet"
  default     = "10.0.1.0/24"
}
