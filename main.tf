module "kubernetes_resources" {
  source         = "./cluster_artefacts"
  cluster_name   = var.cluster_name
  email          = var.email
  tld            = var.tld
  velero         = var.velero
  metrics_server = var.metrics_server
  loki           = var.loki
}
