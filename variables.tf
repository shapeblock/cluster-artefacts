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
  type    = bool
}

variable "loki" {
  type    = bool
}

variable "metrics_server" {
  type    = bool
}
