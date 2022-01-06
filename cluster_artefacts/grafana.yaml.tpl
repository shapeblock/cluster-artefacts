config:
  useGrafanaIniFile: true
  grafanaIniConfigMap: "grafana-ini"

ingress:
  enabled: true
  hostname: ${hostname}
  annotations:
    kubernetes.io/tls-acme: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  ingressClassName: nginx
  tls: true

#TODO: templatize this
admin:
  user: "admin"
  password: "admin123"
