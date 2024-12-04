resource "helm_release" "nginx" {
  name       = "nginx"
  repository = "https://charts.bitnami.com/bitnami"
  #   repository = "oci://registry-1.docker.io/bitnamicharts"
  chart = "nginx"

  values = [
    file("./values/nginx-values.yaml")
  ]
}

data "kubernetes_service" "nginx" {
  depends_on = [helm_release.nginx]
  metadata {
    name = "nginx"
  }
}
