################################################################################
# Vault Helm chart & manifests
################################################################################
resource "helm_release" "vault" {
  name = "vault"

  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  namespace  = "vault"
  #   create_namespace = true
  version = "0.29.1"

  values = [
    templatefile("./values/vault-values.yaml", { kms_key_id = module.kms.key_id })
  ]

  depends_on = [helm_release.argocd, kubernetes_secret_v1.eks_credentials, module.kms]
}

###############################################################################
# Secret
###############################################################################
resource "kubernetes_secret_v1" "eks_credentials" {
  depends_on = [kubectl_manifest.vault_namespace]
  metadata {
    name      = "eks-creds"
    namespace = "vault"
  }

  data = {
    AWS_ACCESS_KEY_ID : "${var.AWS_ACCESS_KEY_ID}"
    AWS_SECRET_ACCESS_KEY : "${var.AWS_SECRET_ACCESS_KEY}"
  }

  type = "Opaque"
}

resource "kubectl_manifest" "vault_namespace" {
  yaml_body  = <<-YAML
    apiVersion: v1
    kind: Namespace
    metadata:
        name: vault
    YAML
  depends_on = [module.eks]
}
