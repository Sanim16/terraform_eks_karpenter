resource "helm_release" "nginx" {
  name       = "nginx"
  repository = "oci://registry-1.docker.io/bitnamicharts"
  #   repository = "https://charts.bitnami.com/bitnami"
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
