# Deploy AWS EKS Cluster using Karpenter via Terraform

[![Github Actions](https://github.com/Sanim16/terraform_eks_karpenter/actions/workflows/infra.yml/badge.svg)](https://github.com/Sanim16/terraform_eks_karpenter/actions/workflows/infra.yml)

>This is a Terraform project that deploys an EKS cluster along with a VPC, KMS(for encryption) and S3 & Dynamodb for backend management. The cluster has a managed node group with `karpenter` installed for provisioning new nodes based on demand.

>Add a github actions workflow for automation

## Technologies:
- Hashicorp Terraform
- AWS VPC
- AWS KMS
- AWS EKS
- AWS S3
- AWS Dynamodb
- Karpenter
- Hashicorp Vault


## Tasks:

- Get access id, secret id from AWS and ensure user has enough permissions to create infrastructure
- Run the following commands
```
terraform init
terraform plan
terraform apply
```
- Uncomment the backend block in provider.tf and rerun the above commands again. This changes the backend from local to remote and uses the newly created S3 bucket and Dynamodb table



- Run `aws eks --region $(terraform output -raw region) update-kubeconfig --name $(terraform output -raw cluster_name)` to create an entry for the cluster in your config file
- Connect to the cluster using `kubectl` and test it.
