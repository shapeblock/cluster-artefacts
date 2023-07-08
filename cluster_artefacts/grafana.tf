// add grafana ini
resource "kubernetes_config_map" "grafana_ini" {
  metadata {
    name = "grafana-ini"
  }

  data = {
    "grafana.ini" = "${file("${path.module}/grafana.ini")}"
  }
}

resource "helm_release" "grafana" {
  name       = "grafana"
  chart      = "grafana"
  repository = "https://charts.bitnami.com/bitnami"
  version    = "9.0.1"

  values = [
    templatefile("${path.module}/grafana.yaml.tpl", { hostname = format("grafana.%s.%s", var.cluster_name, var.tld) })
  ]
}
