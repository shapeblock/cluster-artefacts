# Disable default monitoring components
kubeApiServer:
  enabled: false

kubelet:
  enabled: true
  namespace: kube-system
  serviceMonitor:
    https: true
    # Required for GKE/EKS/most managed K8s
    metricRelabelings:
      - action: keep
        sourceLabels: [__name__]
        regex: '(container_memory_working_set_bytes|container_cpu_usage_seconds_total|container_memory_rss|container_memory_cache|container_memory_swap|container_memory_usage_bytes|container_cpu_cfs_throttled_seconds_total|container_fs_reads_bytes_total|container_fs_writes_bytes_total)'

kubeControllerManager:
  enabled: false

coreDns:
  enabled: false

kubeDns:
  enabled: false

kubeEtcd:
  enabled: false

kubeScheduler:
  enabled: false

kubeProxy:
  enabled: false

nodeExporter:
  enabled: true

# Keep only kube-state-metrics
kubeStateMetrics:
  enabled: true

# Prometheus configuration
prometheus:
  enabled: true
  prometheusSpec:
    retention: 24h
    storageSpec: {}
    securityContext:
      fsGroup: 2000
      runAsNonRoot: true
      runAsUser: 1000
    podMonitorSelectorNilUsesHelmValues: false
    serviceMonitorSelectorNilUsesHelmValues: false
    basicAuth:
      enabled: true
      username: admin
      password: ${prometheus_password}
  ingress:
    enabled: true
    ingressClassName: nginx
    annotations:
      kubernetes.io/ingress.class: nginx
      cert-manager.io/cluster-issuer: "letsencrypt-prod"
    hosts:
      - ${prometheus_domain}
    tls:
      - secretName: prometheus-tls
        hosts:
          - ${prometheus_domain}

# Grafana configuration
grafana:
  enabled: true
  persistence:
    enabled: false
  adminPassword: ${grafana_password}

  # Authentication configuration
  auth:
    disable_login_form: false
    signout_redirect_url: ""
    anonymous:
      enabled: true
      org_role: Viewer
  # Security settings
  grafana.ini:
    security:
      allow_embedding: true
      cookie_secure: true
      cookie_samesite: none
      disable_initial_admin_creation: false
    auth:
      disable_login_form: false
      signout_redirect_url: ""
    auth.anonymous:
      enabled: true
      org_role: Viewer
    session:
      provider: memory
      provider_config: ""
      cookie_name: grafana_session
      cookie_secure: true
      cookie_samesite: none
      session_life_time: 86400

  # Disable default dashboards
  defaultDashboardsEnabled: false
  defaultDashboardsTimezone: utc

  dashboardProviders:
    dashboardproviders.yaml:
      apiVersion: 1
      providers:
      - name: 'default'
        orgId: 1
        folder: ''
        type: file
        disableDeletion: false
        editable: true
        options:
          path: /var/lib/grafana/dashboards/default

  sidecar:
    dashboards:
      enabled: true
      label: grafana_dashboard
      labelValue: "1"
      searchNamespace: ALL
      provider:
        allowUiUpdates: true
        disableDelete: false
        folder: ""
        name: sidecar
        type: file
      defaultFolderName: "General"

  ingress:
    enabled: true
    ingressClassName: nginx
    annotations:
      kubernetes.io/ingress.class: nginx
      cert-manager.io/cluster-issuer: "letsencrypt-prod"
      nginx.ingress.kubernetes.io/enable-cors: "true"
      nginx.ingress.kubernetes.io/cors-allow-methods: "GET, POST, OPTIONS"
      nginx.ingress.kubernetes.io/cors-allow-credentials: "true"
      nginx.ingress.kubernetes.io/cors-allow-origin: "*"
    hosts:
      - ${grafana_domain}
    tls:
      - secretName: grafana-tls
        hosts:
          - ${grafana_domain}

# Disable Alertmanager
alertmanager:
  enabled: false

# Disable default rules and dashboards
defaultRules:
  create: false
  rules:
    alertmanager: false
    etcd: false
    general: false
    k8s: false
    kubeApiserver: false
    kubePrometheusNodeAlerting: false
    kubePrometheusNodeRecording: false
    kubernetesAbsent: false
    kubernetesApps: false
    kubernetesResources: false
    kubernetesStorage: false
    kubernetesSystem: false
    kubeScheduler: false
    network: false
    node: false
    prometheus: false
    prometheusOperator: false
    time: false
