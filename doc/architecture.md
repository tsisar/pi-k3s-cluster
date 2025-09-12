# Архітектура K3s кластера на Raspberry Pi

Цей документ описує архітектуру та компоненти K3s кластера, розгорнутого на Raspberry Pi.

---

## Загальна архітектура

```
┌─────────────────────────────────────────────────────────────────┐
│                        Raspberry Pi Cluster                     │
├─────────────────────────────────────────────────────────────────┤
│  Master Node (Pi 5)           │  Worker Node 1 (Pi 5)           │
│  ┌─────────────────────────┐  │  ┌─────────────────────────┐    │
│  │ K3s Control Plane       │  │  │ K3s Agent               │    │
│  │ - API Server            │  │  │ - kubelet               │    │
│  │ - etcd                  │  │  │ - kube-proxy            │    │
│  │ - Controller Manager    │  │  │ - containerd            │    │
│  │ - Scheduler             │  │  └─────────────────────────┘    │
│  └─────────────────────────┘  │                                 │
│  ┌─────────────────────────┐  │  Worker Node 2 (Pi 4)           │
│  │ InfluxDB                │  │  ┌─────────────────────────┐    │
│  │ - Time Series DB        │  │  │ K3s Agent               │    │
│  │ - Metrics Storage       │  │  │ - kubelet               │    │
│  └─────────────────────────┘  │  │ - kube-proxy            │    │
│                               │  │ - containerd            │    │
│                               │  └─────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

---

## Компоненти кластера

### Основна інфраструктура

#### K3s
- **Версія**: v1.28+
- **Архітектура**: Single binary Kubernetes
- **Storage**: SQLite (etcd не потрібен)
- **Networking**: Flannel (VXLAN)
- **Container Runtime**: containerd

#### NGINX Ingress Controller
- **Версія**: v1.8+
- **Функції**: 
  - HTTP/HTTPS маршрутизація
  - TLS termination
  - Load balancing
  - Rate limiting

### Безпека та аутентифікація

#### Keycloak
- **Версія**: v26.1.1
- **Функції**:
  - OAuth2/OpenID Connect
  - JWT токени
  - User management
  - Role-based access control
- **Storage**: PostgreSQL

#### HashiCorp Vault
- **Версія**: v1.15+
- **Функції**:
  - Secrets management
  - Auto-unseal
  - PKI certificates
  - Dynamic secrets
- **Storage**: Raft

#### Cert-Manager
- **Версія**: v1.13+
- **Функції**:
  - Automatic TLS certificates
  - Let's Encrypt integration
  - Certificate lifecycle management

### Моніторинг та спостереження

#### Prometheus
- **Версія**: v2.45+
- **Функції**:
  - Metrics collection
  - Alerting rules
  - Service discovery
- **Storage**: Local storage

#### Grafana
- **Версія**: v10.0+
- **Функції**:
  - Dashboards
  - Alerting
  - Data visualization
- **Data Sources**: Prometheus, InfluxDB

#### Telegraf
- **Версія**: v1.28+
- **Функції**:
  - Metrics collection from Pi
  - System metrics
  - Custom metrics
- **Output**: InfluxDB

#### InfluxDB
- **Версія**: v2.7+
- **Функції**:
  - Time series database
  - Metrics storage
  - Data retention
- **Location**: Master node

### CI/CD та управління

#### ArgoCD
- **Версія**: v2.8+
- **Функції**:
  - GitOps
  - Application deployment
  - Sync management
  - Rollback capabilities

#### KrakenD
- **Версія**: v2.5+
- **Функції**:
  - API Gateway
  - JWT authentication
  - Rate limiting
  - Request/response transformation

#### Redis
- **Версія**: v7.0+
- **Функції**:
  - Caching
  - Session storage
  - Message queuing

---

## Мережева архітектура

### Внутрішня мережа
```
┌─────────────────────────────────────────────────────────────────┐
│                    Internal Network (192.168.88.0/24)           │
├─────────────────────────────────────────────────────────────────┤
│  Master: 192.168.88.30    │  Worker1: 192.168.88.31             │
│  - K3s API: 6443          │  - K3s Agent                        │
│  - InfluxDB: 8086         │  - Telegraf                         │
│  - Grafana: 3000          │  - Pods                             │
│  - Vault: 8200            │                                     │
│  - Keycloak: 8080         │  Worker2: 192.168.88.32             │
│  - KrakenD: 8080          │  - K3s Agent                        │
│  - ArgoCD: 8080           │  - Telegraf                         │
│  - Prometheus: 9090       │  - Pods                             │
└─────────────────────────────────────────────────────────────────┘
```

### Ingress маршрути
```
┌─────────────────────────────────────────────────────────────────┐
│                        Ingress Routes                           │
├─────────────────────────────────────────────────────────────────┤
│  auth.k3s-rakia.local     → Keycloak (8080)                     │
│  vault.k3s-rakia.local    → Vault (8200)                        │
│  grafana.k3s-rakia.local  → Grafana (3000)                      │
│  argocd.k3s-rakia.local   → ArgoCD (8080)                       │
│  api.k3s-rakia.local      → KrakenD (8080)                      │
│  prometheus.k3s-rakia.local → Prometheus (9090)                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Схема розгортання

### Namespace структура
```
┌─────────────────────────────────────────────────────────────────┐
│                        Kubernetes Namespaces                    │
├─────────────────────────────────────────────────────────────────┤
│  kube-system          │  System components                      │
│  - k3s pods           │  - CoreDNS                              │
│  - traefik (disabled) │  - local-path-provisioner               │
│                       │  - metrics-server                       │
├─────────────────────────────────────────────────────────────────┤
│  ingress-nginx        │  NGINX Ingress Controller               │
│  - nginx-controller   │  - nginx-controller-admission           │
├─────────────────────────────────────────────────────────────────┤
│  cert-manager         │  Certificate management                 │
│  - cert-manager       │  - cert-manager-cainjector              │
│  - cert-manager-webhook │  - cert-manager-controller            │
├─────────────────────────────────────────────────────────────────┤
│  vault                │  HashiCorp Vault                        │
│  - vault-0, vault-1, vault-2 │  - vault-webhook                 │
├─────────────────────────────────────────────────────────────────┤
│  keycloak             │  Keycloak authentication                │
│  - keycloak           │  - keycloak-postgres                    │
├─────────────────────────────────────────────────────────────────┤
│  monitoring           │  Monitoring stack                       │
│  - prometheus         │  - grafana                              │
│  - telegraf           │  - influxdb                             │
├─────────────────────────────────────────────────────────────────┤
│  argocd               │  GitOps                                 │
│  - argocd-server      │  - argocd-application-controller        │
│  - argocd-redis       │  - argocd-repo-server                   │
├─────────────────────────────────────────────────────────────────┤
│  krakend-lab          │  API Gateway                            │
│  - krakend-bff        │  - echo-api                             │
└─────────────────────────────────────────────────────────────────┘
```

---

## Схема даних

### Метрики потік
```
┌─────────────────────────────────────────────────────────────────┐
│                        Metrics Flow                             │
├─────────────────────────────────────────────────────────────────┤
│  Raspberry Pi Nodes                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │   Telegraf  │  │   Telegraf  │  │   Telegraf  │              │
│  │   (Pi 5)    │  │   (Pi 5)    │  │   (Pi 4)    │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
│         │                 │                 │                   │
│         └─────────────────┼─────────────────┘                   │
│                           │                                     │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                InfluxDB (Master)                        │    │
│  │  - System metrics                                       │    │
│  │  - Temperature data                                     │    │
│  │  - Network stats                                        │    │
│  └─────────────────────────────────────────────────────────┘    │
│                           │                                     │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                Grafana                                  │    │
│  │  - Dashboards                                           │    │
│  │  - Alerts                                               │    │
│  │  - Data visualization                                   │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

### Kubernetes метрики
```
┌─────────────────────────────────────────────────────────────────┐
│                    Kubernetes Metrics                           │
├─────────────────────────────────────────────────────────────────┤
│  K3s Cluster                                                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │   Master    │  │   Worker1   │  │   Worker2   │              │
│  │   Node      │  │   Node      │  │   Node      │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
│         │                 │                 │                   │
│         └─────────────────┼─────────────────┘                   │
│                           │                                     │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                Prometheus                               │    │
│  │  - Node metrics                                         │    │
│  │  - Pod metrics                                          │    │
│  │  - Service metrics                                      │    │
│  └─────────────────────────────────────────────────────────┘    │
│                           │                                     │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                Grafana                                  │    │
│  │  - Kubernetes dashboards                                │    │
│  │  - Cluster overview                                     │    │
│  │  - Resource utilization                                 │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

---

## Безпека

### TLS сертифікати
- **Let's Encrypt**: Автоматичні сертифікати для всіх доменів
- **Self-signed**: Внутрішні сертифікати для сервісів
- **Vault PKI**: Додаткові сертифікати через Vault

### Аутентифікація
- **Keycloak**: Централізована аутентифікація
- **JWT токени**: Для API доступу
- **RBAC**: Role-based access control

### Секрети
- **Vault**: Централізоване управління секретами
- **Kubernetes Secrets**: Локальні секрети
- **Auto-unseal**: Автоматичне розпечатування Vault

---

## Масштабування

### Горизонтальне масштабування
- **Worker nodes**: Додавання нових Pi як worker'ів
- **Pods**: Автоматичне масштабування підів
- **Services**: Load balancing між репліками

### Вертикальне масштабування
- **Resource limits**: CPU/Memory limits для підів
- **Node capacity**: Використання ресурсів нод
- **Storage**: Розширення сховища

---

## Backup та відновлення

### Backup стратегія
- **etcd**: Автоматичний backup через K3s
- **Vault**: Backup ключів та конфігурації
- **InfluxDB**: Backup метрик
- **ConfigMaps/Secrets**: Git-based backup

### Відновлення
- **Disaster recovery**: Відновлення з backup
- **Rollback**: Відкат до попередньої версії
- **Migration**: Перенесення на нові ноди

---

## Моніторинг та алерти

### Ключові метрики
- **Node health**: CPU, Memory, Disk, Temperature
- **Pod status**: Running, Pending, Failed
- **Service health**: HTTP status, Response time
- **Storage**: Disk usage, I/O performance

### Алерти
- **High CPU usage**: >80% на 5 хвилин
- **High memory usage**: >90% на 5 хвилин
- **High temperature**: >70°C на 2 хвилини
- **Pod failures**: Pod в статусі Failed
- **Service down**: HTTP 5xx errors

---

## Troubleshooting

### Загальні проблеми
- **Node not ready**: Перевірка kubelet статусу
- **Pod stuck**: Перевірка ресурсів та конфігурації
- **Network issues**: Перевірка Flannel та DNS
- **Storage issues**: Перевірка local-path-provisioner

### Логи
- **K3s logs**: `journalctl -u k3s`
- **Pod logs**: `kubectl logs <pod-name>`
- **Service logs**: `kubectl logs -l app=<service-name>`
- **System logs**: `journalctl -f`

