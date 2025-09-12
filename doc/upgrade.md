# Ubuntu Upgrade Playbooks

Ці playbooks призначені для оновлення Ubuntu систем в кластері K3s.

## Playbooks

### 1. `upgrade-ubuntu.yml`
Базовий playbook для оновлення всіх пакетів Ubuntu.

**Використання:**
```bash
make upgrade-ubuntu
# або
ansible-playbook -i inventory/cluster.ini playbooks/upgrade-ubuntu.yml
```

**Що робить:**
- Оновлює списки пакетів
- Встановлює всі доступні оновлення
- Видаляє застарілі пакети
- Очищає кеш пакетів
- Перезавантажує систему якщо потрібно

### 2. `upgrade-ubuntu-safe.yml`
Безпечний playbook з додатковими перевірками.

**Використання:**
```bash
make upgrade-ubuntu-safe
# або
ansible-playbook -i inventory/cluster.ini playbooks/upgrade-ubuntu-safe.yml
```

**Що робить:**
- Виконує pre-upgrade перевірки (диск, сервіси)
- Створює backup важливих конфігурацій
- Оновлює пакети з додатковими опціями безпеки
- Перевіряє сервіси після оновлення
- Відображає детальну інформацію про процес

### 3. `upgrade-security.yml`
Playbook для встановлення тільки оновлень безпеки.

**Використання:**
```bash
make upgrade-security
# або
ansible-playbook -i inventory/cluster.ini playbooks/upgrade-security.yml
```

**Що робить:**
- Встановлює інструменти для автоматичних оновлень
- Налаштовує unattended-upgrades
- Встановлює тільки оновлення безпеки
- Перевіряє критичні вразливості
- Налаштовує автоматичні оновлення безпеки

## Змінні

### `upgrade-ubuntu.yml`
- `upgrade_timeout` - таймаут оновлення в секундах (за замовчуванням: 1800)
- `reboot_required` - чи потрібне перезавантаження (автоматично визначається)

### `upgrade-ubuntu-safe.yml`
- `upgrade_timeout` - таймаут оновлення в секундах (за замовчуванням: 1800)
- `backup_enabled` - чи створювати backup конфігурацій (за замовчуванням: true)
- `service_checks` - список сервісів для перевірки після оновлення

### `upgrade-security.yml`
- `security_packages` - список пакетів для безпеки
- `unattended_upgrades` - налаштування автоматичних оновлень

## Приклади використання

### Базове оновлення
```bash
# Оновити всі пакети на всіх нодах
make upgrade-ubuntu

# Оновити тільки на master ноді
ansible-playbook -i inventory/cluster.ini playbooks/upgrade-ubuntu.yml --limit master
```

### Безпечне оновлення
```bash
# Безпечне оновлення з перевірками
make upgrade-ubuntu-safe

# З кастомним таймаутом
ansible-playbook -i inventory/cluster.ini playbooks/upgrade-ubuntu-safe.yml -e upgrade_timeout=3600
```

### Оновлення безпеки
```bash
# Встановити тільки оновлення безпеки
make upgrade-security

# Вимкнути backup
ansible-playbook -i inventory/cluster.ini playbooks/upgrade-security.yml -e backup_enabled=false
```

## Рекомендації

### Для продакшн середовища
```bash
# Використовуйте безпечний playbook
make upgrade-ubuntu-safe
```

### Для критичних систем
```bash
# Спочатку оновлення безпеки
make upgrade-security

# Потім повне оновлення
make upgrade-ubuntu-safe
```

### Для тестового середовища
```bash
# Базове оновлення
make upgrade-ubuntu
```

## Моніторинг

### Перевірка статусу після оновлення
```bash
# Статус кластера
make cluster-status

# Статус сервісів
kubectl --context=local-k3s get pods --all-namespaces
```

### Перевірка логів
```bash
# Логи оновлення
journalctl -u unattended-upgrades

# Логи перезавантаження
journalctl -b
```

## Troubleshooting

### Проблеми з оновленням
```bash
# Перевірка доступних оновлень
ansible all -i inventory/cluster.ini -m shell -a "apt list --upgradable"

# Перевірка проблемних пакетів
ansible all -i inventory/cluster.ini -m shell -a "dpkg --configure -a"
```

### Проблеми з сервісами
```bash
# Перевірка статусу сервісів
ansible all -i inventory/cluster.ini -m systemd -a "name=k3s state=started"

# Перезапуск сервісів
ansible all -i inventory/cluster.ini -m systemd -a "name=k3s state=restarted"
```

### Відкат змін
```bash
# Відновлення з backup
ansible all -i inventory/cluster.ini -m copy -a "src=/tmp/backup-{{ inventory_hostname }}/{{ item }} dest={{ item }}"
```
