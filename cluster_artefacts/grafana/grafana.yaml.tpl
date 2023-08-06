grafana:
  updateStrategy:
    type: Recreate

dashboardsProvider:
  enabled: true
  
dashboardsConfigMaps:
- configMapName: prometheus-dashboard
  fileName: prometheus-dashboard.json
- configMapName: loki-dashboard
  fileName: loki-dashboard.json


datasources:
  secretName: datasource-secret

ingress:
  enabled: true
  hostname: ${hostname}
  annotations:
    kubernetes.io/tls-acme: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  tls: true
  ingressClassName: nginx

#TODO: templatize this
admin:
  user: "admin"
  password: "${password}"
