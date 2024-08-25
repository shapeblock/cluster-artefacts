// add grafana ini
resource "kubernetes_config_map" "grafana_ini" {
  metadata {
    name = "grafana-ini"
  }

  data = {
    "grafana.ini" = file("${path.module}/grafana/grafana.ini")
  }
  count = var.loki ? 1 : 0
}

// prometheus dashboard configmap
resource "kubernetes_config_map" "prometheus" {
  metadata {
    name = "prometheus-dashboard"
  }

  data = {
    "prometheus-dashboard.json" = file("${path.module}/grafana/prometheus-dashboard.json")
  }
  count = var.loki ? 1 : 0
}

// loki dashboard configmap
resource "kubernetes_config_map" "loki" {
  metadata {
    name = "loki-dashboard"
  }

  data = {
    "loki-dashboard.json" = file("${path.module}/grafana/loki-dashboard.json")
  }
  count = var.loki ? 1 : 0
}

// kubernetes dashboard configmap
resource "kubernetes_config_map" "kubernetes" {
  metadata {
    name = "kubernetes-dashboard"
  }

  data = {
    "kubernetes-dashboard.json" = file("${path.module}/grafana/kubernetes-dashboard.json")
  }
  count = var.loki ? 1 : 0
}


// prometheus, loki datasource secret
resource "kubernetes_secret" "datasources" {
  metadata {
    name = "datasource-secret"
  }

  data = {
    "datasources.yml" = file("${path.module}/grafana/datasources.yml")
  }
  count = var.loki ? 1 : 0
}

// password for grafana
resource "random_password" "grafana_password" {
  length = 30
  count  = var.loki ? 1 : 0
}

resource "helm_release" "grafana" {
  name       = "grafana"
  chart      = "grafana"
  repository = "https://charts.bitnami.com/bitnami"
  version    = "9.0.5"

  values = [
    templatefile("${path.module}/grafana/grafana.yaml.tpl", { hostname = format("grafana.%s.%s", var.cluster_name, var.tld), password = random_password.grafana_password.0.result })
  ]
  depends_on = [kubernetes_config_map.grafana_ini.0, kubernetes_config_map.prometheus.0, kubernetes_config_map.loki.0, kubernetes_config_map.kubernetes.0, kubernetes_secret.datasources.0, random_password.grafana_password.0]
  count      = var.loki ? 1 : 0
}

// helm upgrade --install grafana bitnami/grafana --version 9.0.1 -f grafana-values.yaml
