data "aws_caller_identity" "current" {}

module "kms" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-kms.git?ref=fe1beca2118c0cb528526e022a53381535bb93cd" # commit hash of version 3.1.0

  description = "EKS Cluster"
  key_usage   = "ENCRYPT_DECRYPT"

  # Policy
  key_administrators                = [data.aws_caller_identity.current.arn, "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root", "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/Aws_admin_Sani"]
  key_owners                        = [data.aws_caller_identity.current.arn, "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root", "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/Aws_admin_Sani"]
  key_service_roles_for_autoscaling = ["arn:aws:iam::${var.aws_account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"]

  # Aliases
  aliases = ["eks/dev-cluster"]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
