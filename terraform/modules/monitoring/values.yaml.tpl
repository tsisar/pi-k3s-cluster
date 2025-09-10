prometheus:
  prometheusSpec:
    serviceMonitorSelectorNilUsesHelmValues: false
    retention: "30d"
    retentionSize: "18GB"
    additionalScrapeConfigs:
      - job_name: 'kubernetes-pods'
        kubernetes_sd_configs:
          - role: pod
        relabel_configs:
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
            action: keep
            regex: true
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
            action: replace
            target_label: __metrics_path__
            regex: (.+)
          - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
            action: replace
            regex: ([^:]+)(?::\d+)?;(\d+)
            replacement: $1:$2
            target_label: __address__
          - source_labels: [__meta_kubernetes_pod_name]
            action: replace
            target_label: kubernetes_pod_name
grafana:
  adminPassword: "${grafana_password}"
  forceAdminPassword: false
  defaultDashboardsEnabled: true
  dashboardProviders:
    dashboardproviders.yaml:
      apiVersion: 1
      providers:
        - name: "default"
          orgId: 1
          folder: ""
          type: file
          disableDeletion: false
          editable: true
          options:
            path: /var/lib/grafana/dashboards/default
  dashboardsConfigMaps:
    default: "grafana-dashboards"
  datasources:
    datasources.yaml:
      apiVersion: 1
      datasources:
        - name: InfluxDB
          type: influxdb
          access: proxy
          url: http://${influxdb_host}:${influxdb_port}
          secureJsonData:
            token: ${influxdb_token}
          jsonData:
            version: Flux
            organization: ${influxdb_org}
            defaultBucket: ${influxdb_bucket}
            tlsSkipVerify: true
          isDefault: false
          editable: true