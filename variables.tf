variable "cluster_name" {
  description = "Name of the Kubernetes cluster."
  type        = string
}

variable "email" {
  type = string
}

variable "tld" {
  type = string
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
  default = false
}

variable "registry" {
  type    = bool
  default = true
}

variable "nfs" {
  type    = bool
  default = false
}

variable "cert_manager" {
  type    = bool
  default = false
}
