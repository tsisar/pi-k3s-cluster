# Promtail Helm chart values (templated)
config:
  clients:
    - url: "http://loki-gateway.monitoring.svc.cluster.local/loki/api/v1/push"

tolerations:
  - key: node-role.kubernetes.io/control-plane
    operator: Exists
    effect: NoSchedule

serviceMonitor:
  enabled: false

resources:
  requests:
    cpu: 50m
    memory: 128Mi
  limits:
    cpu: 200m
    memory: 256Mi
