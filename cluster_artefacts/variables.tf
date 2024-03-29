variable "cluster_name" {
  description = "Name of the k8s cluster."
}

variable "email" {
  description = "Email used for Lets Encrypt certificate issuer"
}

variable "registry_storage_size" {
  description = "Docker registry disk storage size"
  default     = "80Gi"
}

variable "tld" {
  description = "Top level domain"
}

variable "velero" {
  type = bool
}

variable "loki" {
  type = bool
}

variable "metrics_server" {
  type = bool
}

variable "ingress" {
  type    = bool
  default = true
}

variable "registry" {
  type    = bool
  default = true
}

variable "nfs" {
  type    = bool
  default = true
}

variable "cert_manager" {
  type    = bool
  default = true
}

variable "openebs" {
  type    = bool
  default = false
}

variable "node_count" {
  type = number
}

variable "dnsimple_token" {
  type = string
}

variable "dnsimple_account" {
  type = number
}
