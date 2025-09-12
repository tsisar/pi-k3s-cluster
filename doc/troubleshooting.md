# Troubleshooting Guide

Цей документ містить рішення найпоширеніших проблем при роботі з K3s кластером.

---

## Загальні проблеми

### 1. Нода не підключається до кластера

#### Симптоми
- Worker нода не з'являється в `kubectl get nodes`
- Помилки підключення в логах k3s-agent

#### Діагностика
```bash
# Перевірка статусу сервісу
sudo systemctl status k3s-agent

# Перевірка логів
sudo journalctl -u k3s-agent -f

# Перевірка підключення до master
telnet <master-ip> 6443
```

#### Рішення
```bash
# Перевірка токену
sudo cat /var/lib/rancher/k3s/server/node-token

# Перевірка URL master'а
curl -k https://<master-ip>:6443/ping

# Перезапуск сервісу
sudo systemctl restart k3s-agent
```

### 2. Поди не запускаються

#### Симптоми
- Поди в статусі `Pending` або `CrashLoopBackOff`
- Помилки в `kubectl describe pod`

#### Діагностика
```bash
# Детальна інформація про под
kubectl describe pod <pod-name> -n <namespace>

# Логи пода
kubectl logs <pod-name> -n <namespace>

# Події в namespace
kubectl get events -n <namespace>
```

#### Рішення
```bash
# Перевірка ресурсів ноди
kubectl describe node <node-name>

# Перевірка доступного простору
df -h

# Перевірка пам'яті
free -h

# Очищення невикористаних образів
sudo crictl rmi --prune
```

### 3. Проблеми з мережею

#### Симптоми
- Поди не можуть спілкуватися між собою
- DNS не працює
- Ingress не маршрутизує трафік

#### Діагностика
```bash
# Перевірка Flannel
kubectl get pods -n kube-system | grep flannel

# Перевірка CoreDNS
kubectl get pods -n kube-system | grep coredns

# Тест DNS
kubectl run -it --rm debug --image=busybox -- nslookup kubernetes.default

# Перевірка мережевих політик
kubectl get networkpolicies --all-namespaces
```

#### Рішення
```bash
# Перезапуск Flannel
kubectl delete pod -n kube-system -l app=flannel

# Перезапуск CoreDNS
kubectl delete pod -n kube-system -l k8s-app=kube-dns

# Перевірка iptables
sudo iptables -L -n

# Очищення iptables (обережно!)
sudo iptables -F
sudo systemctl restart k3s
```

### 4. Проблеми зі сховищем

#### Симптоми
- PVC не можуть бути створені
- Помилки "no available persistent volume"
- Поди не можуть монтувати volumes

#### Діагностика
```bash
# Перевірка storage class
kubectl get storageclass

# Перевірка PV
kubectl get pv

# Перевірка PVC
kubectl get pvc --all-namespaces

# Перевірка local-path-provisioner
kubectl get pods -n kube-system | grep local-path
```

#### Рішення
```bash
# Перезапуск local-path-provisioner
kubectl delete pod -n kube-system -l app=local-path-provisioner

# Перевірка прав доступу
sudo chown -R 1000:1000 /opt/local-path-provisioner

# Очищення невикористаних PV
kubectl delete pv <pv-name>
```

---

## Проблеми з конкретними компонентами

### 1. Keycloak

#### Проблема: Keycloak не запускається
```bash
# Перевірка логів
kubectl logs -n keycloak keycloak-0

# Перевірка підключення до БД
kubectl exec -n keycloak keycloak-0 -- env | grep KC_DB

# Перевірка PostgreSQL
kubectl logs -n keycloak keycloak-postgres-0
```

#### Рішення
```bash
# Перезапуск Keycloak
kubectl delete pod -n keycloak keycloak-0

# Перевірка конфігурації БД
kubectl get configmap -n keycloak keycloak-config -o yaml
```

### 2. Vault

#### Проблема: Vault запечатаний
```bash
# Перевірка статусу
kubectl exec -n vault vault-0 -- vault status

# Перевірка ключів
kubectl get secret -n vault vault-keys

# Розпечатування
kubectl exec -n vault vault-0 -- vault operator unseal <unseal-key>
```

#### Рішення
```bash
# Ініціалізація Vault
kubectl exec -n vault vault-0 -- vault operator init

# Збереження ключів
kubectl create secret generic vault-keys \
  --from-literal=unseal-key=<key> \
  --from-literal=root-token=<token> \
  -n vault
```

### 3. Prometheus

#### Проблема: Метрики не збираються
```bash
# Перевірка статусу
kubectl get pods -n monitoring

# Перевірка конфігурації
kubectl get configmap -n monitoring prometheus-config -o yaml

# Тест запиту
kubectl port-forward -n monitoring svc/prometheus 9090:9090
curl http://localhost:9090/api/v1/targets
```

#### Рішення
```bash
# Перезапуск Prometheus
kubectl delete pod -n monitoring -l app=prometheus

# Перевірка ServiceMonitor
kubectl get servicemonitor --all-namespaces
```

### 4. Grafana

#### Проблема: Дашборди не завантажуються
```bash
# Перевірка логів
kubectl logs -n monitoring -l app=grafana

# Перевірка підключення до Prometheus
kubectl exec -n monitoring grafana-0 -- curl http://prometheus:9090/api/v1/query?query=up
```

#### Рішення
```bash
# Перезапуск Grafana
kubectl delete pod -n monitoring -l app=grafana

# Перевірка конфігурації
kubectl get configmap -n monitoring grafana-config -o yaml
```

---

## Проблеми з оновленнями

### 1. Ubuntu оновлення

#### Проблема: Оновлення зависає
```bash
# Перевірка процесів
ps aux | grep apt

# Перевірка блокувальників
sudo lsof /var/lib/dpkg/lock-frontend

# Очищення блокувальників
sudo rm /var/lib/dpkg/lock-frontend
sudo rm /var/lib/apt/lists/lock
sudo dpkg --configure -a
```

#### Рішення
```bash
# Перезапуск сервісів
sudo systemctl restart apt-daily
sudo systemctl restart apt-daily-upgrade

# Очищення кешу
sudo apt clean
sudo apt autoremove

# Повторне оновлення
sudo apt update && sudo apt upgrade
```

### 2. K3s оновлення

#### Проблема: Кластер не оновлюється
```bash
# Перевірка версії
kubectl version

# Перевірка статусу нод
kubectl get nodes

# Перевірка логів
sudo journalctl -u k3s -f
```

#### Рішення
```bash
# Оновлення K3s
curl -sfL https://get.k3s.io | sh -

# Перезапуск сервісу
sudo systemctl restart k3s

# Перевірка підключення
kubectl get nodes
```

---

## Проблеми з продуктивністю

### 1. Висока завантаженість CPU

#### Діагностика
```bash
# Перевірка CPU
top
htop

# Перевірка підів
kubectl top pods --all-namespaces

# Перевірка нод
kubectl top nodes
```

#### Рішення
```bash
# Обмеження ресурсів
kubectl patch deployment <deployment> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container>","resources":{"limits":{"cpu":"500m"}}}]}}}}'

# Масштабування
kubectl scale deployment <deployment> --replicas=2
```

### 2. Висока завантаженість пам'яті

#### Діагностика
```bash
# Перевірка пам'яті
free -h

# Перевірка swap
swapon -s

# Перевірка підів
kubectl top pods --all-namespaces
```

#### Рішення
```bash
# Очищення кешу
sudo sync
echo 3 | sudo tee /proc/sys/vm/drop_caches

# Обмеження пам'яті
kubectl patch deployment <deployment> -p '{"spec":{"template":{"spec":{"containers":[{"name":"<container>","resources":{"limits":{"memory":"512Mi"}}}]}}}}'
```

### 3. Проблеми з диском

#### Діагностика
```bash
# Перевірка дискового простору
df -h

# Перевірка I/O
iostat -x 1

# Перевірка логів
sudo journalctl --disk-usage
```

#### Рішення
```bash
# Очищення логів
sudo journalctl --vacuum-time=7d

# Очищення Docker
sudo docker system prune -a

# Очищення K3s
sudo crictl rmi --prune
```

---

## Проблеми з безпекою

### 1. TLS сертифікати

#### Проблема: Сертифікати не генеруються
```bash
# Перевірка cert-manager
kubectl get pods -n cert-manager

# Перевірка Certificate
kubectl get certificate --all-namespaces

# Перевірка логів
kubectl logs -n cert-manager -l app=cert-manager
```

#### Рішення
```bash
# Перезапуск cert-manager
kubectl delete pod -n cert-manager -l app=cert-manager

# Перевірка ClusterIssuer
kubectl get clusterissuer

# Тест створення сертифікату
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: test-cert
  namespace: default
spec:
  secretName: test-cert-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - test.example.com
EOF
```

### 2. Аутентифікація

#### Проблема: JWT токени не валідуються
```bash
# Перевірка Keycloak
kubectl logs -n keycloak keycloak-0 | grep -i error

# Тест токену
curl -H "Authorization: Bearer <token>" https://api.k3s-rakia.local/api/v1/protected
```

#### Рішення
```bash
# Перевірка конфігурації KrakenD
kubectl get configmap -n krakend-lab krakend-config -o yaml

# Перевірка JWK URL
curl https://auth.k3s-rakia.local/realms/master/protocol/openid-connect/certs
```

---

## Корисні команди

### Діагностика кластера
```bash
# Загальний статус
kubectl get all --all-namespaces

# Статус нод
kubectl get nodes -o wide

# Події
kubectl get events --sort-by=.metadata.creationTimestamp

# Логи всіх підів
kubectl logs --all-containers=true --all-namespaces=true
```

### Очищення ресурсів
```bash
# Видалення невикористаних ресурсів
kubectl delete pods --field-selector=status.phase=Succeeded
kubectl delete pods --field-selector=status.phase=Failed

# Очищення невикористаних образів
sudo crictl rmi --prune

# Очищення невикористаних volumes
kubectl delete pvc --all-namespaces --field-selector=status.phase=Bound
```

### Backup та відновлення
```bash
# Backup конфігурації
kubectl get all --all-namespaces -o yaml > cluster-backup.yaml

# Backup секретів
kubectl get secrets --all-namespaces -o yaml > secrets-backup.yaml

# Відновлення
kubectl apply -f cluster-backup.yaml
kubectl apply -f secrets-backup.yaml
```

---

## Контакти та підтримка

### Логи та звіти
- **K3s logs**: `sudo journalctl -u k3s -f`
- **System logs**: `sudo journalctl -f`
- **Pod logs**: `kubectl logs <pod-name> -n <namespace>`

### Моніторинг
- **Grafana**: http://grafana.k3s-rakia.local
- **Prometheus**: http://prometheus.k3s-rakia.local
- **ArgoCD**: http://argocd.k3s-rakia.local

### Корисні посилання
- [K3s Documentation](https://k3s.io/docs/)
- [Kubernetes Troubleshooting](https://kubernetes.io/docs/tasks/debug-application-cluster/)
- [K3s Documentation](https://k3s.io/)

