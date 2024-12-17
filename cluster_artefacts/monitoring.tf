resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
  count = var.prometheus ? 1 : 0
}

resource "random_password" "prometheus" {
  length  = 16
  special = false
  count = var.prometheus ? 1 : 0
}

resource "random_password" "grafana" {
  length  = 16
  special = false
  count = var.prometheus ? 1 : 0
}

resource "helm_release" "prometheus" {
  name       = "prometheus-stack"
  namespace  = kubernetes_namespace.monitoring[0].metadata[0].name
  chart      = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  version    = "51.5.1"

  depends_on = [kubernetes_namespace.monitoring]

  values = [
    templatefile("${path.module}/prometheus-values.yaml.tpl", {
      prometheus_domain   = format("prometheus.%s", var.tld)
      grafana_domain     = format("grafana.%s", var.tld)
      prometheus_password = random_password.prometheus[0].result
      grafana_password   = random_password.grafana[0].result
    })
  ]
  count = var.prometheus ? 1 : 0
}

resource "kubernetes_config_map" "grafana_dashboards" {
  metadata {
    name      = "grafana-dashboards"
    namespace = kubernetes_namespace.monitoring[0].metadata[0].name
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "pod-metrics-dashboard.json"        = file("${path.module}/grafana/dashboards/pod-metrics-dashboard.json")
    "kube-state-metrics-dashboard.json" = file("${path.module}/grafana/dashboards/kube-state-metrics-dashboard.json")
  }

  depends_on = [helm_release.prometheus]
  count      = var.prometheus ? 1 : 0
}
