output "ingress_ip" {
  value = var.ingress ? data.kubernetes_service.ingress_controller.status.0.load_balancer.0.ingress.0.hostname : ""
}
