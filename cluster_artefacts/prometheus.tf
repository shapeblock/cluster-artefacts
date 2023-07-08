resource "helm_release" "prometheus" {
  name       = "prometheus"
  chart      = "kube-prometheus"
  repository = "https://charts.bitnami.com/bitnami"
  version    = "8.15.1"

  values = [
    templatefile("${path.module}/prometheus.yaml.tpl", { hostname = format("prometheus.%s.%s", var.cluster_name, var.tld) })
  ]
}
