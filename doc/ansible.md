# K3s Raspberry Pi Cluster Provisioning with Ansible

Автоматизація розгортання кластеру K3s на Raspberry Pi (1 master + N worker'ів) за допомогою Ansible.

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
pi0 ansible_host=192.168.88.30 new_hostname=pi-k3s-master-01

[workers]
pi1 ansible_host=192.168.88.31 new_hostname=pi-k3s-worker-01
pi2 ansible_host=192.168.88.32 new_hostname=pi-k3s-worker-02

[pi:vars]
ansible_user=pi
ansible_ssh_private_key_file=~/.ssh/k3s
ansible_python_interpreter=/usr/bin/python3
kube_context_name=local-k3s
```

## Вимоги

- Raspberry Pi з Ubuntu 24.04 LTS
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
- Налаштування збору метрик Raspberry Pi
- Запуск сервісу

```bash
make setup-telegraf
```

#### `setup-dashboards.yml`
Імпорт Grafana дашбордів:
- Встановлення Grafana
- Імпорт дашбордів для Raspberry Pi
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

## Видалення K3s

На будь-якому Pi:
```bash
sudo /usr/local/bin/k3s-uninstall.sh
```