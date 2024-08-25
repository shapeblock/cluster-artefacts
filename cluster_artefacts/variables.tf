variable "cluster_name" {
  description = "Name of the k8s cluster."
}

variable "sb_url" {
  type = string
}
variable "cluster_uuid" {
  type = string
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

variable "prometheus" {
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

variable "sb_operator_image" {
  description = "Shapeblock operator image repo"
  default     = "ghcr.io/shapeblock/operator"
}

variable "sb_operator_tag" {
  description = "Shapeblock operator image tag"
  default     = "v1.0.1"
}
