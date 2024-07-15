apiVersion: apps/v1
kind: Deployment
metadata:
  name: sb-operator
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      application: sb-operator
  template:
    metadata:
      labels:
        application: sb-operator
    spec:
      serviceAccountName: sb-admin
      containers:
      - name: sb-operator
        image: shapeblock/sb-operator:15-july-2024-15.37
        imagePullPolicy: Always
        livenessProbe:
          failureThreshold: 3
          httpGet:
            path: /healthz
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 5
          periodSeconds: 30
        env:
          - name: SB_URL
            value: ${sb_url}
          - name: CLUSTER_ID
            value: ${cluster_uuid}
