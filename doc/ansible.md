# K3s Cluster Provisioning with Ansible

Автоматизація розгортання кластеру K3s (1 master + N worker'ів) за допомогою Ansible.

## Структура

```
ansible/
├── ansible.cfg                 # Конфігурація Ansible
├── inventory/
│   └── cluster.ini             # Інвентар хостів (master і worker-и)
└── playbooks/
    ├── setup-ubuntu.yml        # Підготовка Ubuntu системи
    ├── setup-influxdb.yml      # Встановлення InfluxDB
    ├── setup-telegraf.yml      # Налаштування Telegraf
    ├── setup-dashboards.yml    # Імпорт Grafana дашбордів
    ├── setup-k3s.yml           # Встановлення K3s на master і worker'и
    ├── label-nodes.yml         # Маркування нодів за типом процесора
    ├── copy-cluster-config.yml # Копіювання kubeconfig
    ├── copy-cluster-secrets.yml # Копіювання сертифікатів
    ├── setup-cluster-access.yml # Налаштування доступу до кластера
    ├── upgrade-ubuntu.yml      # Оновлення Ubuntu
    ├── upgrade-ubuntu-safe.yml # Безпечне оновлення Ubuntu
    ├── upgrade-security.yml    # Оновлення безпеки
    └── test-connection.yml     # Тестування підключення
```

## Інвентар

Файл `ansible/inventory/cluster.ini`:

```ini
[master]
ser0 ansible_host=192.168.88.30 new_hostname=k3s-master-01 node_type=i3

[workers]
ser1 ansible_host=192.168.88.31 new_hostname=k3s-worker-01 node_type=i3
ser2 ansible_host=192.168.88.32 new_hostname=k3s-worker-02 node_type=celeron
ser3 ansible_host=192.168.88.33 new_hostname=k3s-worker-03 node_type=celeron
ser4 ansible_host=192.168.88.34 new_hostname=k3s-worker-04 node_type=ryzen

[ser:children]
master
workers

[ser:vars]
kube_context_name=k3s-cluster
ansible_user=k3s
ansible_password=k3s
ansible_become=true
ansible_become_method=sudo
ansible_become_password=k3s
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args=-o StrictHostKeyChecking=no
```

## Вимоги

- Сервери з Ubuntu 24.04 LTS (або сумісний дистрибутив)
- Ansible ≥ 2.10
- kubectl встановлений локально для управління кластером
- Наявність SSH ключа, який дозволяє підключення без пароля

## Швидкий старт

### Повне налаштування кластера
```bash
# Використовуючи Makefile
make full

# Або вручну
ansible-playbook -i inventory/cluster.ini playbooks/setup-ubuntu.yml
ansible-playbook -i inventory/cluster.ini playbooks/setup-influxdb.yml
ansible-playbook -i inventory/cluster.ini playbooks/setup-telegraf.yml
ansible-playbook -i inventory/cluster.ini playbooks/setup-dashboards.yml
ansible-playbook -i inventory/cluster.ini playbooks/setup-k3s.yml
ansible-playbook -i inventory/cluster.ini playbooks/setup-cluster-access.yml
```

## Детальний опис playbooks

### 1. Підготовка системи

#### `setup-ubuntu.yml`
Підготовка Ubuntu системи для K3s:
- Оновлення системи
- Встановлення hostname
- Встановлення iptables
- Вимикання та видалення swap
- Додавання cgroup параметрів
- Налаштування DNS резолюції
- Перезавантаження за потреби

```bash
make setup-ubuntu
```

#### `setup-influxdb.yml`
Встановлення InfluxDB на master ноді:
- Встановлення InfluxDB
- Налаштування бази даних
- Створення користувачів
- Налаштування retention policy

```bash
make setup-influxdb
```

#### `setup-telegraf.yml`
Налаштування Telegraf на всіх нодах:
- Встановлення Telegraf
- Налаштування конфігурації
- Налаштування збору метрик нодів
- Запуск сервісу

```bash
make setup-telegraf
```

#### `setup-dashboards.yml`
Імпорт Grafana дашбордів:
- Встановлення Grafana
- Імпорт дашбордів для нодів
- Налаштування джерел даних

```bash
make setup-dashboards
```

### 2. Встановлення K3s

#### `setup-k3s.yml`
Встановлення K3s кластера:
- Встановлення K3s master (без Traefik)
- Встановлення K3s на worker'и
- Підключення worker'ів до master
- Налаштування базових сервісів

```bash
make setup-k3s
```

### 3. Управління кластером

#### `copy-cluster-config.yml`
Копіювання kubeconfig з master ноди:
- Отримання kubeconfig з master
- Заміна 127.0.0.1 на реальний IP
- Об'єднання з локальним kubeconfig

```bash
make copy-config
```

#### `copy-cluster-secrets.yml`
Копіювання сертифікатів та секретів:
- Копіювання CA сертифікатів
- Копіювання client сертифікатів
- Копіювання node token
- Встановлення правильних прав доступу

```bash
make copy-secrets
```

#### `setup-cluster-access.yml`
Повне налаштування доступу до кластера:
- Виконує copy-cluster-config.yml
- Виконує copy-cluster-secrets.yml
- Перевіряє доступ до кластера
- Відображає інформацію про кластер

```bash
make setup-cluster-access
```

### 4. Оновлення системи

#### `upgrade-ubuntu.yml`
Базове оновлення Ubuntu:
- Оновлення списків пакетів
- Встановлення всіх оновлень
- Видалення застарілих пакетів
- Очищення кешу
- Перезавантаження за потреби

```bash
make upgrade-ubuntu
```

#### `upgrade-ubuntu-safe.yml`
Безпечне оновлення з перевірками:
- Pre-upgrade перевірки (диск, сервіси)
- Backup важливих конфігурацій
- Оновлення з додатковими опціями безпеки
- Post-upgrade перевірки
- Детальний моніторинг процесу

```bash
make upgrade-ubuntu-safe
```

#### `upgrade-security.yml`
Оновлення тільки безпеки:
- Встановлення інструментів автоматичних оновлень
- Налаштування unattended-upgrades
- Встановлення тільки оновлень безпеки
- Перевірка критичних вразливостей

```bash
make upgrade-security
```

### 5. Тестування

#### `test-connection.yml`
Тестування підключення до всіх нод:
- Перевірка SSH підключення
- Перевірка доступності сервісів
- Відображення статусу нод

```bash
make test-connection
```

## Перевірка кластера

### Статус кластера
```bash
# Використовуючи Makefile
make cluster-status

# Або вручну
kubectl --context=local-k3s get nodes
kubectl --context=local-k3s get pods --all-namespaces
```

### Тестування підключення
```bash
make test-connection
```

## Управління оновленнями

### Рекомендований порядок
```bash
# 1. Спочатку оновлення безпеки
make upgrade-security

# 2. Потім безпечне оновлення
make upgrade-ubuntu-safe

# 3. Перевірка статусу
make cluster-status
```

### Для продакшн середовища
```bash
# Використовуйте тільки безпечне оновлення
make upgrade-ubuntu-safe
```

## Troubleshooting

### Проблеми з підключенням
```bash
# Перевірка SSH
ansible all -i inventory/cluster.ini -m ping

# Перевірка статусу сервісів
ansible all -i inventory/cluster.ini -m systemd -a "name=k3s state=started"
```

### Проблеми з оновленням
```bash
# Перевірка доступних оновлень
ansible all -i inventory/cluster.ini -m shell -a "apt list --upgradable"

# Перевірка проблемних пакетів
ansible all -i inventory/cluster.ini -m shell -a "dpkg --configure -a"
```

### Відкат змін
```bash
# Відновлення з backup
ansible all -i inventory/cluster.ini -m copy -a "src=/tmp/backup-{{ inventory_hostname }}/{{ item }} dest={{ item }}"
```

## Маркування нодів (Node Labeling)

Кластер автоматично маркує ноди за типом процесора для контролю розміщення подів.

### Поточні лейбли

- **k3s-master-01**: `node-type=i3`
- **k3s-worker-01**: `node-type=i3`  
- **k3s-worker-02**: `node-type=celeron`
- **k3s-worker-03**: `node-type=celeron`
- **k3s-worker-04**: `node-type=ryzen`

### Використання в Deployment'ах

#### nodeSelector (простий спосіб)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      nodeSelector:
        node-type: i3  # Розміщувати тільки на i3 нодах
      containers:
      - name: my-app
        image: nginx
```

#### nodeAffinity (більш гнучкий)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: node-type
                operator: In
                values:
                - i3
                - ryzen  # Розміщувати на i3 або ryzen нодах
      containers:
      - name: my-app
        image: nginx
```

#### Приклад: Розміщення на потужних нодах
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: heavy-workload
spec:
  template:
    spec:
      nodeSelector:
        node-type: ryzen  # Тільки на Ryzen ноді
      containers:
      - name: heavy-workload
        image: my-heavy-app
        resources:
          requests:
            cpu: "2"
            memory: "4Gi"
```

### Оновлення лейблів

```bash
# Оновити лейбли всіх нодів
ansible-playbook -i inventory/cluster.ini playbooks/label-nodes.yml

# Перевірити поточні лейбли
ansible ser0 -i inventory/cluster.ini -m shell -a "kubectl get nodes --show-labels"
```

### Додавання нових лейблів

Для додавання нових лейблів відредагуйте `inventory/cluster.ini`:

```ini
[master]
ser0 ansible_host=192.168.88.30 new_hostname=k3s-master-01 node_type=i3 storage_type=ssd

[workers]
ser1 ansible_host=192.168.88.31 new_hostname=k3s-worker-01 node_type=i3 storage_type=ssd
ser2 ansible_host=192.168.88.32 new_hostname=k3s-worker-02 node_type=celeron storage_type=hdd
ser3 ansible_host=192.168.88.33 new_hostname=k3s-worker-03 node_type=celeron storage_type=hdd
ser4 ansible_host=192.168.88.34 new_hostname=k3s-worker-04 node_type=ryzen storage_type=nvme
```

## Видалення K3s

На будь-якій ноді:
```bash
sudo /usr/local/bin/k3s-uninstall.sh
```