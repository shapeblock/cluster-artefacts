resource "kubernetes_namespace" "openebs" {
  lifecycle {
    ignore_changes = [metadata]
  }

  metadata {
    name = "openebs"
  }
  count = var.openebs ? 1 : 0
}

resource "time_sleep" "wait_30_seconds" {
  depends_on       = [kubernetes_namespace.0.openebs]
  destroy_duration = "30s"
}

resource "helm_release" "openebs" {
  repository = "https://openebs.github.io/charts"
  chart      = "openebs"
  name       = "openebs"
  namespace  = "openebs"
  timeout    = 600
  depends_on = [time_sleep.wait_30_seconds]
  version    = "3.7.0"

  set {
    name  = "jiva.storageClass.isDefaultClass"
    value = true
  }
  set {
    name  = "jiva.enabled"
    value = true
  }
  set {
    name  = "localpv-provisioner.enabled"
    value = true
  }
  set {
    name  = "jiva.csiNode.kubeletDir"
    value = "/var/snap/microk8s/common/var/lib/kubelet/"
  }
  set {
    name  = "jiva.defaultPolicy.replicas"
    value = var.node_count > 3 ? 3 : var.node_count
  }
  count = var.openebs ? 1 : 0
}
// helm upgrade --install openebs openebs/openebs -n openebs --set jiva.storageClass.isDefaultClass=true --set jiva.enabled=true --set localpv-provisioner.enabled=true --set jiva.csiNode.kubeletDir="/var/snap/microk8s/common/var/lib/kubelet/" --set jiva.defaultPolicy.replicas=1 # change to 3 later
