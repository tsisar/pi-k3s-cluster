# Loki Helm chart values (templated, production-ready)
deploymentMode: SingleBinary

loki:
  auth_enabled: false

  # Keep single replica in SingleBinary
  commonConfig:
    replication_factor: 1

  # Retention policy
  limits_config:
    allow_structured_metadata: false
    retention_period: "${retention_days}d"

  # Local filesystem storage (fits k3s/home-lab; can swap to S3/GCS later)
  storage:
    type: filesystem

  # Explicit TSDB schema (no test schema, applies cleanly on new cluster)
  schemaConfig:
    configs:
      - from: "2024-01-01"
        store: boltdb-shipper
        object_store: filesystem
        schema: v13
        index:
          prefix: index_
          period: 24h

  # Optional but sane defaults for rules/compactor/WAL
  rulerConfig:
    storage:
      type: local
      local:
        directory: /rules
  compactor:
    working_directory: /var/loki/compactor
  ingester:
    wal:
      enabled: true

singleBinary:
  replicas: 1
  persistence:
    enabled: ${persistence_enabled}
    size: ${storage_size}
%{ if storage_class_name != "" }
    storageClassName: ${storage_class_name}
%{ endif }
  resources:
    requests:
      cpu: 100m
      memory: 512Mi
    limits:
      cpu: 500m
      memory: 1Gi

# Ensure scalable targets are disabled in SingleBinary mode
read:
  replicas: 0
write:
  replicas: 0
backend:
  replicas: 0

gateway:
  enabled: true
  replicas: 1
  service:
    type: ClusterIP

monitoring:
  dashboards:
    enabled: false
  rules:
    enabled: false
  alerts:
    enabled: false
  selfMonitoring:
    enabled: false
