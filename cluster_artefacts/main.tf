provider "kubernetes" {
  config_path = "kubeconfig"
}

provider "kubectl" {
  config_path = "kubeconfig"
}

provider "helm" {
  kubernetes {
    config_path = "kubeconfig"
  }
}


resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
  count = var.cert_manager ? 1 : 0
}

resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
  count = var.ingress ? 1 : 0
}

resource "random_password" "registry_password" {
  length = 30
  count  = var.registry ? 1 : 0
}

resource "null_resource" "encrypted_registry_password" {
  triggers = {
    orig = random_password.registry_password.0.result
    pw   = bcrypt(random_password.registry_password.0.result)
  }

  lifecycle {
    ignore_changes = [triggers["pw"]]
  }
  count = var.registry ? 1 : 0
}


// registry
resource "helm_release" "registry" {
  name       = "docker-registry"
  chart      = "docker-registry"
  repository = "https://helm.twun.io"
  version    = "2.2.2"

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
    name  = "ingress.annotations.cert-manager\\.io/cluster-issuer"
    value = "letsencrypt-prod"
  }

  set {
    name  = "ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/proxy-body-size"
    value = "0"
  }

  set {
    name  = "secrets.htpasswd"
    value = format("%s:%s", var.cluster_name, null_resource.encrypted_registry_password.0.triggers["pw"])
  }

  set {
    name  = "updateStrategy.type"
    value = "Recreate"
  }
  count = var.registry ? 1 : 0

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
    value = "40Gi"
  }
  count = var.nfs ? 1 : 0
}

// ingress
resource "helm_release" "ingress" {
  name       = "nginx-ingress"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "nginx-ingress-controller"
  version    = "9.7.5"
  namespace  = "ingress-nginx"
  timeout    = 600
  count      = var.ingress ? 1 : 0
}

// cert manager
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.12.2"
  namespace  = "cert-manager"
  set {
    name  = "installCRDs"
    value = true
  }
  count = var.cert_manager ? 1 : 0
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
  version    = "0.1.6"
  namespace  = "kpack"
}

data "kubectl_path_documents" "kpack_manifests" {
  pattern = "${path.module}/kpack/*.yaml"
}

resource "kubectl_manifest" "cluster_stores" {
  count      = length(data.kubectl_path_documents.kpack_manifests.documents)
  yaml_body  = element(data.kubectl_path_documents.kpack_manifests.documents, count.index)
  depends_on = [helm_release.kpack]
}

// helm release
// create namespace
resource "kubernetes_namespace" "flux" {
  lifecycle {
    ignore_changes = [metadata]
  }

  metadata {
    name = "flux"
  }
}

resource "time_sleep" "wait_30_seconds_flux" {
  depends_on       = [kubernetes_namespace.flux]
  destroy_duration = "30s"
}

// helm
resource "helm_release" "helm_operator" {
  name       = "helm-operator"
  chart      = "flux2"
  repository = "https://fluxcd-community.github.io/helm-charts"
  version    = "2.9.0"
  namespace  = "flux"

  set {
    name  = "imageautomationcontroller.create"
    value = false
  }

  set {
    name  = "imagereflectorcontroller.create"
    value = false
  }

  set {
    name  = "kustomizecontroller.create"
    value = false
  }
}

data "kubectl_file_documents" "sb_repository" {
  content = file("${path.module}/sb-repository.yaml")
}

resource "kubectl_manifest" "sb_repository" {
  count              = length(data.kubectl_file_documents.sb_repository.documents)
  yaml_body          = element(data.kubectl_file_documents.sb_repository.documents, count.index)
  depends_on         = [helm_release.helm_operator]
  override_namespace = "flux"
}


// Loki
resource "kubernetes_namespace" "logging" {
  metadata {
    name = "logging"
  }
  count = var.loki ? 1 : 0
}

resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  version    = "2.9.10"
  namespace  = "logging"
  depends_on = [kubernetes_namespace.logging]
  count      = var.loki ? 1 : 0
  values = [
    file("${path.module}/loki-values.yaml")
  ]
}

// Velero
resource "kubernetes_namespace" "velero" {
  metadata {
    name = "velero"
  }
  count = var.velero ? 1 : 0
}

resource "helm_release" "velero" {
  name       = "velero"
  repository = "https://vmware-tanzu.github.io/helm-charts"
  chart      = "velero"
  version    = "4.1.3"
  namespace  = "velero"
  count      = var.velero ? 1 : 0
  depends_on = [kubernetes_namespace.velero]
}

// read loadbalancer IP
data "kubernetes_service" "ingress_controller" {
  metadata {
    name      = "nginx-ingress-nginx-ingress-controller"
    namespace = "ingress-nginx"
  }
  depends_on = [helm_release.ingress]
}


locals {
  ingress_hostname = data.kubernetes_service.ingress_controller.status.0.load_balancer.0.ingress.0.hostname
  ingress_ip       = data.kubernetes_service.ingress_controller.status.0.load_balancer.0.ingress.0.ip
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
      "auth": "${base64encode("${var.cluster_name}:${random_password.registry_password.0.result}")}"
    }
  }
}
DOCKER
  }

  type  = "kubernetes.io/dockerconfigjson"
  count = var.registry ? 1 : 0
}

data "kubernetes_secret" "container_registry" {
  metadata {
    name      = "registry-creds"
    namespace = "default"
  }
  depends_on = [kubernetes_secret.container_registry.0]
}
