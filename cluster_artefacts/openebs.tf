resource "kubernetes_namespace" "openebs" {
  lifecycle {
    ignore_changes = [metadata]
  }

  metadata {
    name = "openebs"
  }
}

resource "time_sleep" "wait_30_seconds" {
  depends_on       = [kubernetes_namespace.openebs]
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
    name  = "cstor.enabled"
    value = true
  }
  set {
    name  = "nfs-provisioner.enabled"
    value = true
  }
}
