# ###############################################################################
# # EKS
# ###############################################################################
# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "~> 20.0"

#   cluster_name    = var.cluster_name
#   cluster_version = var.cluster_version

#   cluster_endpoint_public_access = true

#   cluster_addons = {
#     coredns                = {}
#     eks-pod-identity-agent = {}
#     kube-proxy             = {}
#     vpc-cni                = {}
#     aws-ebs-csi-driver = {
#       most_recent              = true
#       service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
#     }
#   }

#   vpc_id                   = module.vpc.vpc_id
#   subnet_ids               = module.vpc.private_subnets
#   control_plane_subnet_ids = module.vpc.intra_subnets


#   # EKS Managed Node Group(s)
#   eks_managed_node_group_defaults = {
#     instance_types = ["m5.large", "m5n.large", "m5zn.large", "t3.small", "t3.medium"]
#   }

#   eks_managed_node_groups = {
#     first = {
#       name = "node-grp-1"

#       # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
#       ami_type       = "AL2023_x86_64_STANDARD"
#       instance_types = ["t3.medium"]
#       # capacity_type  = "SPOT"

#       min_size     = 0
#       max_size     = 3
#       desired_size = 2

#       taints = {
#         # This Taint aims to keep just EKS Addons and Karpenter running on this MNG
#         # The pods that do not tolerate this taint should run on nodes created by Karpenter
#         addons = {
#           key    = "CriticalAddonsOnly"
#           value  = "true"
#           effect = "NO_SCHEDULE"
#         },
#       }

#       block_device_mappings = {
#         xvda = {
#           device_name = "/dev/xvda"
#           ebs = {
#             volume_size           = 20
#             volume_type           = "gp3"
#             iops                  = 3000
#             throughput            = 125
#             encrypted             = true
#             kms_key_id            = module.kms.key_arn
#             delete_on_termination = true
#           }
#         }
#       }
#     }
#   }

#   # Cluster access entry
#   # To add the current caller identity as an administrator
#   enable_cluster_creator_admin_permissions = true

#   access_entries = {
#     # One access entry with a policy associated
#     example = {
#       kubernetes_groups = []
#       principal_arn     = var.user

#       policy_associations = {
#         example = {
#           policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
#           access_scope = {
#             namespaces = []
#             type       = "cluster"
#           }
#         }
#       }
#     }
#   }

#   create_kms_key = false
#   cluster_encryption_config = {
#     resources        = ["secrets"]
#     provider_key_arn = module.kms.key_arn
#   }

#   node_security_group_tags = {
#     "karpenter.sh/discovery" = var.cluster_name
#   }

#   tags = {
#     Environment = "dev"
#     Terraform   = "true"
#     "karpenter.sh/discovery" = var.cluster_name
#   }
# }

# ###############################################################################
# # KARPENTER
# ###############################################################################
# module "karpenter" {
#   source = "terraform-aws-modules/eks/aws//modules/karpenter"

#   cluster_name = module.eks.cluster_name

#   enable_v1_permissions = true

#   enable_pod_identity = true
#   create_pod_identity_association = true

#   # Used to attach additional IAM policies to the Karpenter node IAM role
#   node_iam_role_additional_policies = {
#     AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
#   }

#   # create_node_iam_role = false
#   # node_iam_role_arn    = module.eks.eks_managed_node_groups["first"].iam_role_arn

#   # # Since the node group role will already have an access entry
#   # create_access_entry = false

#   tags = {
#     Environment = "dev"
#     Terraform   = "true"
#   }
# }

# ###############################################################################
# # EBS CSI
# ###############################################################################
# module "ebs_csi_irsa_role" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#   version = "5.44.0"

#   role_name = "one-ebs-csi"

#   attach_ebs_csi_policy = true
#   ebs_csi_kms_cmk_ids   = [module.kms.key_arn]

#   oidc_providers = {
#     ex = {
#       provider_arn               = module.eks.oidc_provider_arn
#       namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
#     }
#   }

#   tags = {
#     Environment = "dev"
#     Terraform   = "true"
#   }
# }

# data "aws_eks_addon_version" "ebs_csi" {
#   addon_name         = "aws-ebs-csi-driver"
#   kubernetes_version = "1.30"
#   most_recent        = true
# }

# ###############################################################################
# # Storage Class
# ###############################################################################
# resource "kubectl_manifest" "ebs_csi_default_storage_class" {
#   yaml_body = <<-YAML
#   apiVersion: storage.k8s.io/v1
#   kind: StorageClass
#   metadata:
#     annotations:
#       storageclass.kubernetes.io/is-default-class: "true"
#     name: gp3-default
#   provisioner: ebs.csi.aws.com
#   reclaimPolicy: Delete
#   volumeBindingMode: WaitForFirstConsumer
#   allowVolumeExpansion: true
#   parameters:
#     type: gp3  
#     fsType: ext4
#     encrypted: "true"
#     kmsKeyId: "${module.kms.key_arn}"
#   YAML
# }

# ################################################################################
# # Karpenter Helm chart & manifests
# ################################################################################

# resource "helm_release" "karpenter" {
#   namespace           = "kube-system"
#   name                = "karpenter"
#   repository          = "oci://public.ecr.aws/karpenter"
#   repository_username = data.aws_ecrpublic_authorization_token.token.user_name
#   repository_password = data.aws_ecrpublic_authorization_token.token.password
#   chart               = "karpenter"
#   version             = "1.0.8"
#   wait                = false

#   values = [
#     <<-EOT
#     serviceAccount:
#       name: ${module.karpenter.service_account}
#     settings:
#       clusterName: ${module.eks.cluster_name}
#       clusterEndpoint: ${module.eks.cluster_endpoint}
#       interruptionQueue: ${module.karpenter.queue_name}
#     EOT
#   ]
# }

# resource "kubectl_manifest" "karpenter_node_class" {
#   yaml_body = <<-YAML
#     apiVersion: karpenter.k8s.aws/v1
#     kind: EC2NodeClass
#     metadata:
#       name: default
#     spec:
#       amiFamily: AL2023
#       role: ${module.karpenter.node_iam_role_name}
#       subnetSelectorTerms:
#         - tags:
#             karpenter.sh/discovery: ${module.eks.cluster_name}
#       securityGroupSelectorTerms:
#         - tags:
#             karpenter.sh/discovery: ${module.eks.cluster_name}
#       amiSelectorTerms:
#         - id: "ami-09c6d3a030e81a3ad"
#         - id: "ami-0eff9a20e584c7411"
#       tags:
#         karpenter.sh/discovery: ${module.eks.cluster_name}
#   YAML

#   depends_on = [
#     helm_release.karpenter
#   ]
# }

# resource "kubectl_manifest" "karpenter_node_pool" {
#   yaml_body = <<-YAML
#     apiVersion: karpenter.sh/v1
#     kind: NodePool
#     metadata:
#       name: default
#     spec:
#       template:
#         spec:
#           nodeClassRef:
#             group: karpenter.k8s.aws
#             kind: EC2NodeClass
#             name: default
#           requirements:
#             - key: kubernetes.io/arch
#               operator: In
#               values: ["amd64"]
#             - key: kubernetes.io/os
#               operator: In
#               values: ["linux"]
#             - key: karpenter.sh/capacity-type
#               operator: In
#               values: ["spot", "on-demand"]
#             - key: karpenter.k8s.aws/instance-category
#               operator: In
#               values: ["c", "m", "t"]
#             - key: karpenter.k8s.aws/instance-generation
#               operator: Gt
#               values: ["2"]
#             - key: "karpenter.k8s.aws/instance-cpu"
#               operator: In
#               values: ["2", "4", "8", "16", "32"]
#             - key: "karpenter.k8s.aws/instance-hypervisor"
#               operator: In
#               values: ["nitro"]
#           expireAfter: 72h
#       limits:
#         cpu: 1000
#       disruption:
#         consolidationPolicy: WhenEmptyOrUnderutilized
#         consolidateAfter: 30s
#   YAML

#   depends_on = [
#     kubectl_manifest.karpenter_node_class
#   ]
# }
