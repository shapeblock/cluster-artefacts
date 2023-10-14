prometheus:
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
  additionalScrapeConfigs:
    enabled: true
    type: internal
    internal:
      jobList: |
        - job_name: kubernetes-nodes-cadvisor
          scrape_interval: 10s
          scrape_timeout: 10s
          scheme: https  # remove if you want to scrape metrics on insecure port
          tls_config:
            ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
          bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
          kubernetes_sd_configs:
            - role: node
          relabel_configs:
            - action: labelmap
              regex: __meta_kubernetes_node_label_(.+)
            # Only for Kubernetes ^1.7.3.
            # See: https://github.com/prometheus/prometheus/issues/2916
            - target_label: __address__
              replacement: kubernetes.default.svc:443
            - source_labels: [__meta_kubernetes_node_name]
              regex: (.+)
              target_label: __metrics_path__
              replacement: /api/v1/nodes/${1}/proxy/metrics/cadvisor
          metric_relabel_configs:
            - action: replace
              source_labels: [id]
              regex: '^/machine\.slice/machine-rkt\\x2d([^\\]+)\\.+/([^/]+)\.service$'
              target_label: rkt_container_name
              replacement: '${2}-${1}'
            - action: replace
              source_labels: [id]
              regex: '^/system\.slice/(.+)\.service$'
              target_label: systemd_service_name
              replacement: '${1}'      