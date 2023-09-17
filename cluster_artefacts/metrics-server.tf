resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  chart      = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  version    = "3.10.0"
  count      = var.metrics_server ? 1 : 0
  values     = <<EOF
apiService:
  create: true
args:
  - "--kubelet-preferred-address-types=InternalIP"
  - "--kubelet-insecure-tls"
EOF
}
