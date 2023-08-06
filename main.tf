module "kubernetes_resources" {
  source           = "./cluster_artefacts"
  cluster_name     = var.cluster_name
  email            = var.email
  tld              = var.tld
  velero           = var.velero
  metrics_server   = var.metrics_server
  loki             = var.loki
  ingress          = var.ingress
  registry         = var.registry
  nfs              = var.nfs
  cert_manager     = var.cert_manager
  openebs          = var.openebs
  node_count       = var.node_count
  dnsimple_token   = var.dnsimple_token
  dnsimple_account = var.dnsimple_account
}
