module "kubernetes_resources" {
  source            = "./cluster_artefacts"
  email             = var.email
  tld               = var.tld
  velero            = var.velero
  loki              = var.loki
  monitoring        = var.monitoring
  ingress           = var.ingress
  registry          = var.registry
  nfs               = var.nfs
  cert_manager      = var.cert_manager
  openebs           = var.openebs
  node_count        = var.node_count
  cluster_uuid      = var.cluster_uuid
  epinio_username   = var.epinio_username
  epinio_password   = var.epinio_password
}
