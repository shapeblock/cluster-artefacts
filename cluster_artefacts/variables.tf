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

variable "monitoring" {
  type = bool
}

variable "ingress" {
  type    = bool
  default = true
}

variable "registry" {
  type    = bool
  default = false
}

variable "nfs" {
  type    = bool
  default = false
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

variable "sb_url" {
  description = "Shapeblock API URL"
  type        = string
}
