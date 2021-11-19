module "kubernetes_resources" {
  source         = "./cluster_artefacts"
  cluster_name   = var.cluster_name
  email          = var.email
  host           = var.cluster_url
  ca_certificate = base64decode(var.ca_cert)
  token          = var.token
  storage_class  = "gp2"
  tld            = var.tld
}
