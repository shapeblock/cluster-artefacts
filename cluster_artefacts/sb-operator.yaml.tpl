---
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: applications.dev.shapeblock.com
spec:
  group: dev.shapeblock.com
  names:
    kind: Application
    listKind: ApplicationList
    shortNames:
    - app
    - apps
    plural: applications
    singular: application
  scope: Namespaced
  versions:
  - name: v1alpha1
    schema:
      openAPIV3Schema:
        description: Application is the Schema for the applications API
        properties:
          apiVersion:
            type: string
          kind:
            type: string
          metadata:
            type: object
          spec:
            description: ApplicationSpec defines the desired state of Application
            properties:
              stack:
                type: string
                enum: [php, java, python, node, go, ruby, nginx]
              chart:
                properties:
                  name:
                    type: string
                  repo:
                    type: string
                  values:
                    type: string
                  version:
                    type: string
                  build:
                    type: array
                    items:
                      type: object
                      properties:
                        name:
                          type: string
                        value:
                          type: string
                type: object
              git:
                properties:
                  ref:
                    type: string
                  repo:
                    type: string
                  subPath:
                    type: string
                type: object
              serviceAccount:
                type: string
              tag:
                type: string
            type: object
          status:
            x-kubernetes-preserve-unknown-fields: true
            description: ApplicationStatus defines the observed state of Application
            properties:
              deployed:
                description: 'INSERT ADDITIONAL STATUS FIELD - define observed state
                  of cluster Important: Run "make" to regenerate code after modifying
                  this file'
                type: boolean
              image:
                type: string
              ref:
                type: string
            type: object
        type: object
    served: true
    storage: true
    subresources:
      status: {}
status:
  acceptedNames:
    kind: ""
    plural: ""
  conditions: []
  storedVersions: []
---
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: projects.dev.shapeblock.com
spec:
  group: dev.shapeblock.com
  names:
    kind: Project
    listKind: ProjectList
    plural: projects
    singular: project
  scope: Cluster
  versions:
  - name: v1alpha1
    schema:
      openAPIV3Schema:
        type: object
        properties:
          apiVersion:
            type: string
          kind:
            type: string
          metadata:
            type: object
          spec:
            properties:
              name:
                type: string
                description: The human readable name of the project.
              description:
                type: string
                description: What this project is about.
            type: object
    served: true
    storage: true
    subresources:
      status: {}
status:
  acceptedNames:
    kind: ""
    plural: ""
  conditions: []
  storedVersions: []
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: sb-admin
  namespace: default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: sb-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: sb-admin
  namespace: default
---
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
