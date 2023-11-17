grafana:
  updateStrategy:
    type: Recreate

config:
  useGrafanaIniFile: true
  grafanaIniConfigMap: "grafana-ini"

dashboardsProvider:
  enabled: true
  
dashboardsConfigMaps:
- configMapName: prometheus-dashboard
  fileName: prometheus-dashboard.json
- configMapName: loki-dashboard
  fileName: loki-dashboard.json
- configMapName: kubernetes-dashboard
  fileName: kubernetes-dashboard.json


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

admin:
  user: "admin"
  password: "${password}"
