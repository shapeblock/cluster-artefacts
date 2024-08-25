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

resource "kubernetes_namespace" "shapeblock" {
  metadata {
    name = "shapeblock"
  }
}

resource "random_password" "registry_password" {
  length = 30
  count = var.registry ? 1 : 0
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
  name       = "registry"
  chart      = "docker-registry"
  repository = "https://helm.twun.io"
  version    = "2.2.3"
  namespace  = "shapeblock"

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
  namespace  = "shapeblock"

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
  version    = "11.3.18"
  namespace  = "shapeblock"
  timeout    = 600
  count      = var.ingress ? 1 : 0
}

// cert manager
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "cert-manager"
  version    = "1.3.16"
  namespace  = "cert-manager"
  set {
    name  = "installCRDs"
    value = true
  }
  timeout          = 600
  create_namespace = true
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
  chart      = "sb-kpack"
  version    = "0.1.7"
  namespace  = "shapeblock"
}

data "kubectl_path_documents" "kpack_manifests" {
  pattern = "${path.module}/kpack/*.yaml"
}

resource "kubectl_manifest" "cluster_stores" {
  count      = length(data.kubectl_path_documents.kpack_manifests.documents)
  yaml_body  = element(data.kubectl_path_documents.kpack_manifests.documents, count.index)
  depends_on = [helm_release.kpack]
}

// helm
resource "helm_release" "helm_operator" {
  name       = "helm-operator"
  chart      = "flux2"
  repository = "https://fluxcd-community.github.io/helm-charts"
  version    = "2.13.0"
  namespace  = "shapeblock"

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

resource "kubectl_manifest" "sb_repository" {
  yaml_body  = file("${path.module}/sb-repository.yaml")
  depends_on = [helm_release.helm_operator]
}

resource "kubectl_manifest" "bitnami_repository" {
  yaml_body  = file("${path.module}/bitnami-repository.yaml")
  depends_on = [helm_release.helm_operator]
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
  version    = "6.0.0"
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
  version    = "6.0.0"
  namespace  = "velero"
  count      = var.velero ? 1 : 0
  depends_on = [kubernetes_namespace.velero]
}

// read loadbalancer IP
data "kubernetes_service" "ingress_controller" {
  metadata {
    name      = "nginx-ingress-nginx-ingress-controller"
    namespace = "shapeblock"
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
    namespace = "shapeblock"
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

data "kubectl_path_documents" "sb_manifests" {
  pattern = "${path.module}/shapeblock/*.yaml"
}

resource "kubectl_manifest" "shapeblock_crs" {
  count      = length(data.kubectl_path_documents.sb_manifests.documents)
  yaml_body  = element(data.kubectl_path_documents.sb_manifests.documents, count.index)
  depends_on = [helm_release.cert_manager]
}

locals {
  sb_operator_values = templatefile("${path.module}/sb-operator.yaml.tpl", {
    image        = var.sb_operator_image,
    tag          = var.sb_operator_tag,
    sb_url       = var.sb_url,
    cluster_uuid = var.cluster_uuid,
    namespace    = "shapeblock"
  })
}
// SB operator
resource "kubectl_manifest" "sb_operator" {
  yaml_body  = local.sb_operator_values
  depends_on = [kubectl_manifest.shapeblock_crs]
}
