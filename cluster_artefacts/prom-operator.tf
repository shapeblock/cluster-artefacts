resource "kubernetes_namespace" "prom" {
  lifecycle {
    ignore_changes = [metadata]
  }

  metadata {
    name = "prom"
  }
}

resource "time_sleep" "wait_30_seconds" {
  depends_on       = [kubernetes_namespace.prom]
  destroy_duration = "30s"
}

resource "helm_release" "prom" {
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  name       = "prom"
  namespace  = "prom"
  timeout    = 600
  depends_on = [time_sleep.wait_30_seconds]
  version    = "35.2.0"
}
