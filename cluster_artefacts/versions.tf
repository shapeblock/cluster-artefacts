terraform {
  required_version = ">= 0.14"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.1.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.4.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
    dnsimple = {
      source  = "dnsimple/dnsimple"
      version = "1.1.2"
    }
  }
}
