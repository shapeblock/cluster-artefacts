provider "dnsimple" {
  token   = var.dnsimple_token
  account = var.dnsimple_account
}

resource "dnsimple_zone_record" "a_record" {
  zone_name = var.tld
  name      = var.cluster_name
  value     = local.ingress_ip == "" ? local.ingress_hostname : local.ingress_ip
  type      = local.ingress_ip == "" ? "ALIAS" : "A"
}

resource "dnsimple_zone_record" "cname" {
  zone_name = var.tld
  name      = "*.${var.cluster_name}"
  value     = "${var.cluster_name}.${var.tld}"
  type      = "CNAME"
}
