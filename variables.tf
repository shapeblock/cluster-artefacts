variable "cluster_name" {
  description = "Name of the Kubernetes cluster."
  type        = string
}

variable "cluster_url" {
  type = string
}

variable "ca_cert" {
  type = string
}

variable "token" {
  type = string
}

variable "email" {
  type = string
}

variable "tld" {
  type = string
}

variable "velero" {
  type    = bool
  default = false
}