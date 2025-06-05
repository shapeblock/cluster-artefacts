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

resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.namespace
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
  namespace  = var.namespace

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
    value = format("registry.%s", var.tld)
  }

  set {
    name  = "ingress.tls[0].hosts[0]"
    value = format("registry.%s", var.tld)
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
    value = format("%s:%s", var.namespace, null_resource.encrypted_registry_password.0.triggers["pw"])
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
  namespace  = var.namespace

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
  namespace  = var.namespace
  timeout    = 600
  count      = var.ingress ? 1 : 0
}

// cert manager
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "cert-manager"
  version    = "1.3.16"
  namespace  = var.namespace
  set {
    name  = "installCRDs"
    value = true
  }
  timeout          = 600
  create_namespace = true
}

resource "null_resource" "wait_for_cert_manager" {
  provisioner "local-exec" {
    command = "sleep 60"
  }

  depends_on = [helm_release.cert_manager]
}

resource "kubectl_manifest" "cluster_issuer" {
  yaml_body  = templatefile("${path.module}/cert-issuer.yaml.tpl", { email = var.email })
  depends_on = [null_resource.wait_for_cert_manager]
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
    namespace = var.namespace
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
    namespace = var.namespace
  }

  data = {
    ".dockerconfigjson" = <<DOCKER
{
  "auths": {
    "registry.${var.tld}": {
      "auth": "${base64encode("${var.namespace}:${random_password.registry_password.0.result}")}"
    }
  }
}
DOCKER
  }
  type  = "kubernetes.io/dockerconfigjson"
  count = var.registry ? 1 : 0
}

// kubenest operator values
locals {
  operator_values = {
    operator = {
      image = {
        repository = "ghcr.io/kubenesthq/operator"
        tag        = "15-05-2025.10.57"
        pullPolicy = "Always"
      }
    }
    apiUrl       = "${var.sb_url}"
    apiKey       = var.cluster_key
  }

  // Add buildwatch_values
  buildwatch_values = {
    image = {
      repository = "ghcr.io/kubenesthq/buildwatch"
      tag        = "22-05-2025.18.14"
      pullPolicy = "Always"
    }
    config = {
      inCluster     = true
      serverAddress = ":8080"
      backendURL    = var.sb_url
      clusterKey    = var.cluster_key
    }
    ingress = {
      enabled    = true
      className  = "nginx"
      annotations = {
        "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
      }
      host       = format("buildwatch.%s", var.tld)
      tls        = true
      tlsSecret  = "buildwatch-tls"
    }
  }
}

// Install kubenest operator
resource "helm_release" "kubenest_operator" {
  name             = "operator"
  repository       = "oci://ghcr.io/kubenesthq/charts"
  chart            = "kubenest-operator"
  version          = "2.0.4"
  namespace        = kubernetes_namespace.namespace.metadata[0].name
  create_namespace = false

  values = [
    yamlencode(local.operator_values)
  ]

  depends_on = [kubernetes_namespace.namespace]
}

// install buildwatch
resource "helm_release" "buildwatch" {
  name             = "buildwatch"
  repository       = "oci://ghcr.io/kubenesthq/charts"
  chart            = "buildwatch"
  version          = "0.1.3"
  namespace        = kubernetes_namespace.namespace.metadata[0].name
  create_namespace = false

  values = [
    yamlencode(local.buildwatch_values)
  ]

  depends_on = [kubernetes_namespace.namespace]
}
