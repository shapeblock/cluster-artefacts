variable "cluster_name" {
  description = "Name of the Kubernetes cluster."
  type        = string
}

variable "cluster_uuid" {
  type = string
}

variable "email" {
  type = string
}

variable "tld" {
  type        = string
  description = "Top level domain"
}

variable "velero" {
  type    = bool
  default = false
}

variable "loki" {
  type    = bool
  default = false
}

variable "prometheus" {
  type    = bool
  default = false
}

variable "metrics_server" {
  type    = bool
  default = false
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
  type    = number
  default = 1
}

variable "epinio_username" {
  type    = string
}

variable "epinio_password" {
  type    = string
}
