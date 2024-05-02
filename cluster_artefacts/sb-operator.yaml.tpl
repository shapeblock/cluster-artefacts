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
        image: shapeblock/sb-operator:27-feb-2024-13.59
        imagePullPolicy: Always
        env:
          - name: SB_URL
            value: ${sb_url}
          - name: CLUSTER_ID
            value: ${cluster_uuid}
