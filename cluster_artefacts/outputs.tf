output "ingress_ip" {
  value = data.kubernetes_service.ingress_controller.status.0.load_balancer.0.ingress.0.hostname
}
