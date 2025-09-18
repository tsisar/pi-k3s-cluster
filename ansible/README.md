# Ansible Roles for K3s Cluster

Цей репозиторій містить Ansible ролі для налаштування K3s кластера з моніторингом.

## Структура ролей

### Базові ролі
- **`common`** - базові пакети, timezone, chrony
- **`ubuntu`** - Ubuntu 24.04 специфічні налаштування (DNS, kernel modules, sysctl)

### Кластер
- **`k3s`** - встановлення K3s з окремими tasks для master/worker

### Моніторинг
- **`netdata`** - моніторинг з окремими tasks для master/worker
- **`influxdb`** - InfluxDB 2.x для зберігання метрик
- **`telegraf`** - агент збору метрик
- **`dashboards`** - імпорт дашбордів для InfluxDB

### CRD для Terraform
- **`gateway-api`** - CRD для Gateway API
- **`cert-manager`** - CRD для cert-manager
- **`argocd`** - CRD для ArgoCD

## Playbooks

### Послідовність встановлення (з нумерацією)
- **`00-test-connection.yml`** - тест підключення
- **`01-upgrade-ubuntu.yml`** - оновлення Ubuntu
- **`02-setup-ubuntu.yml`** - налаштування Ubuntu
- **`03-install-k3s.yml`** - встановлення K3s
- **`04-label-nodes.yml`** - мітки для вузлів (роль + тип процесора)
- **`05-copy-config.yml`** - копіювання kubeconfig
- **`06-setup-monitoring.yml`** - встановлення моніторингу
- **`07-setup-crds.yml`** - встановлення CRD

### Головний playbook
- **`site.yml`** - все разом (0-7 кроки)

### Спеціалізовані playbooks
- Всі playbooks інтегровані в послідовність

## Використання

### Використання Makefile (рекомендовано)
```bash
# Показати всі доступні команди
make help

# Повне встановлення
make all

# Окремі кроки
make test              # Тест підключення
make upgrade           # Оновлення Ubuntu (за конфігом)
make setup-ubuntu      # Налаштування Ubuntu

# Типи оновлення
make upgrade-normal    # Звичайне оновлення
make upgrade-security  # Тільки безпека
make upgrade-safe      # Безпечне оновлення
make upgrade-skip      # Пропустити оновлення
make upgrade-no-packages # Оновлення без пакетів
make install-k3s       # Встановлення K3s
make label-nodes       # Мітки для вузлів (роль + тип процесора)
make copy-config       # Копіювання kubeconfig
make setup-monitoring  # Встановлення моніторингу
make setup-crds        # Встановлення CRD

# Моніторинг (вибір)
make setup-netdata     # Тільки Netdata
make setup-both        # Обидва (Netdata + InfluxDB)
```

### Пряме використання Ansible
```bash
# Повне встановлення
ansible-playbook playbooks/site.yml

# Окремі кроки
ansible-playbook playbooks/00-test-connection.yml
ansible-playbook playbooks/01-upgrade-ubuntu.yml
ansible-playbook playbooks/02-setup-ubuntu.yml
ansible-playbook playbooks/03-install-k3s.yml
ansible-playbook playbooks/04-copy-config.yml
ansible-playbook playbooks/05-label-nodes.yml
ansible-playbook playbooks/06-setup-monitoring.yml
ansible-playbook playbooks/07-setup-crds.yml
```

### Налаштування моніторингу та оновлення
В файлі `group_vars/all.yml` встановіть:
```yaml
# Моніторинг
monitoring_type: "both"    # "netdata", "influxdb", "both", "none"

# Оновлення
upgrade_type: "safe"       # "normal", "security", "safe", "none"
upgrade_include_packages: true  # true, false
```

## Змінні

### group_vars/
- **`all.yml`** - глобальні змінні
- **`master.yml`** - змінні для master
- **`workers.yml`** - змінні для workers

### Ролі мають свої defaults/
Кожна роль має файл `defaults/main.yml` з налаштуваннями за замовчуванням.

## Залежності

```
common
  └── ubuntu
      └── k3s

common
  └── netdata

common
  └── influxdb
      └── dashboards

common
  └── telegraf
```

## Переваги нової структури

1. **Модульність** - кожна роль відповідає за одну функціональність
2. **Повторне використання** - ролі можна використовувати в інших проектах
3. **Чіткі залежності** - автоматичне встановлення залежностей
4. **Легке тестування** - можна запускати окремі ролі
5. **Управління версіями** - змінні в `group_vars/`
6. **Підтримка** - легше знайти та виправити проблеми
