variable "cluster_name" {
  description = "Name of the k8s cluster."
}

variable "email" {
  description = "Email used for Lets Encrypt certificate issuer"
  default     = "lakshmi.narasimhan@indigo.co.in"
}

variable "token" {
  description = "Kubernetes cluster token"
}

variable "host" {
  description = "Kubernetes cluster host"
}

variable "ca_certificate" {
  description = "Kubernetes cluster CA certificate"
}

variable "registry_storage_size" {
  description = "Docker registry disk storage size"
  default     = "80Gi"
}

variable "tld" {
  description = "Top level domain"
  default     = "dev.indigo-consulting.co.in"
}
