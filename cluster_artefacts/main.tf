provider "kubernetes" {
  host                   = var.host
  token                  = var.token
  cluster_ca_certificate = var.ca_certificate
}

provider "kubectl" {
  load_config_file       = false
  host                   = var.host
  token                  = var.token
  cluster_ca_certificate = var.ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = var.host
    token                  = var.token
    cluster_ca_certificate = var.ca_certificate
  }
}


resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

resource "random_password" "registry_password" {
  length = 30
}

resource "null_resource" "encrypted_registry_password" {
  triggers = {
    orig = random_password.registry_password.result
    pw   = bcrypt(random_password.registry_password.result)
  }

  lifecycle {
    ignore_changes = [triggers["pw"]]
  }
}


// registry
resource "helm_release" "registry" {
  name       = "docker-registry"
  chart      = "docker-registry"
  repository = "https://helm.twun.io"
  version    = "2.1.0"

  set {
    name  = "persistence.enabled"
    value = true
  }

  set {
    name  = "persistence.size"
    value = var.registry_storage_size
  }

  set {
    name  = "ingress.enabled"
    value = true
  }

  set {
    name  = "ingress.hosts[0]"
    value = format("registry.%s.%s", var.cluster_name, var.tld)
  }

  set {
    name  = "ingress.tls[0].hosts[0]"
    value = format("registry.%s.%s", var.cluster_name, var.tld)
  }

  set {
    name  = "ingress.tls[0].secretName"
    value = "registry-tls"
  }

  set {
    name  = "ingress.annotations.kubernetes\\.io/ingress\\.class"
    value = "nginx"
  }

  set {
    name  = "ingress.annotations.cert-manager\\.io/cluster-issuer"
    value = "letsencrypt-prod"
  }

  set {
    name  = "ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/proxy-body-size"
    value = "0"
  }

  set {
    name  = "secrets.htpasswd"
    value = format("%s:%s", var.cluster_name, null_resource.encrypted_registry_password.triggers["pw"])
  }
}

// nfs
resource "helm_release" "nfs" {
  name       = "nfs-server"
  chart      = "nfs-server-provisioner"
  repository = "https://raphaelmonrouzeau.github.io/charts/repository"
  version    = "1.3.0"

  set {
    name  = "persistence.enabled"
    value = true
  }

  set {
    name  = "persistence.size"
    value = "80Gi"
  }
}

// ingress
resource "helm_release" "ingress" {
  name       = "nginx-ingress"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "nginx-ingress-controller"
  version    = "9.1.12"
  namespace  = "ingress-nginx"
  timeout    = 600
}

// cert manager
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.7.2"
  namespace  = "cert-manager"
  set {
    name  = "installCRDs"
    value = true
  }
}

// certificate issuer
resource "kubectl_manifest" "cluster_issuer" {
  yaml_body  = templatefile("${path.module}/cert-issuer.yaml.tpl", { email = var.email })
  depends_on = [helm_release.cert_manager]
}


resource "kubernetes_namespace" "kpack" {
  metadata {
    name = "kpack"
  }
}

resource "helm_release" "kpack" {
  name       = "kpack"
  repository = "https://shapeblock.github.io"
  chart      = "kpack"
  version    = "0.1.2"
  namespace  = "kpack"
}


// helm release
// create namespace
resource "kubernetes_namespace" "flux" {
  metadata {
    name = "flux"
  }
}

data "kubectl_path_documents" "helm_manifests" {
  pattern = "${path.module}/helm-operator/*.yaml"
}

resource "kubectl_manifest" "helm_operator" {
  count      = length(data.kubectl_path_documents.helm_manifests.documents)
  yaml_body  = element(data.kubectl_path_documents.helm_manifests.documents, count.index)
  depends_on = [kubernetes_namespace.flux]
}

// helm
// TODO: Update to Flux 2.x
resource "helm_release" "helm_operator" {
  name       = "helm-operator"
  chart      = "helm-operator"
  repository = "https://charts.fluxcd.io"
  version    = "1.4.2"
  namespace  = "flux"
  set {
    name  = "helm.versions"
    value = "v3"
  }

  set {
    name  = "rbac.create"
    value = true
  }
}


// Loki
resource "kubernetes_namespace" "logging" {
  metadata {
    name = "logging"
  }
}

resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  version    = "2.6.1"
  namespace  = "logging"
}

// Sealed secrets
resource "kubernetes_namespace" "sealed_secrets" {
  metadata {
    name = "sealed-secrets"
  }
}

resource "helm_release" "sealed_secrets" {
  name       = "sealed-secrets-controller"
  repository = "https://bitnami-labs.github.io/sealed-secrets"
  chart      = "sealed-secrets"
  version    = "2.1.4"
  namespace  = "sealed-secrets"
}

// Valero
resource "kubernetes_namespace" "velero" {
  metadata {
    name = "velero"
  }
}

resource "helm_release" "velero" {
  name       = "velero"
  repository = "https://vmware-tanzu.github.io/helm-charts"
  chart      = "velero"
  version    = "2.29.1"
  namespace  = "velero"
}

// read loadbalancer IP
data "kubernetes_service" "ingress_controller" {
  metadata {
    name      = "nginx-ingress-nginx-ingress-controller"
    namespace = "ingress-nginx"
  }
  depends_on = [helm_release.ingress]
}

// create a reference secret which will be copied to other namespaces as needed.
resource "kubernetes_secret" "container_registry" {
  metadata {
    name      = "registry-creds"
    namespace = "default"
  }

  data = {
    ".dockerconfigjson" = <<DOCKER
{
  "auths": {
    "registry.${var.cluster_name}.${var.tld}": {
      "auth": "${base64encode("${var.cluster_name}:${random_password.registry_password.result}")}"
    }
  }
}
DOCKER
  }

  type = "kubernetes.io/dockerconfigjson"
}

data "kubernetes_secret" "container_registry" {
  metadata {
    name      = "registry-creds"
    namespace = "default"
  }
  depends_on = [kubernetes_secret.container_registry]
}
