# Netdata Monitoring Setup

Netdata - це система моніторингу в реальному часі для серверів та контейнерів. В цьому документі описано налаштування Netdata на K3s кластері з master-worker архітектурою.

## Архітектура

- **Master нода** (ser0) - збирає та відображає метрики з усіх нод
- **Worker ноди** (ser1-ser4) - відправляють метрики на master
- **Єдиний дашборд** - доступний на master ноді

## Швидкий старт

### Використання Makefile (Рекомендовано)

```bash
# Повне налаштування Netdata на всіх нодах
make setup-netdata

# Перевірка статусу
make netdata-status

# Перегляд всіх команд
make help
```

### Ручне налаштування

#### Крок 1: Встановлення залежностей

```bash
sudo apt update
sudo apt install -y zlib1g-dev uuid-dev libmnl-dev libuv1-dev liblz4-dev \
  libssl-dev cmake gcc g++ make pkg-config git curl jq netcat-openbsd
```

#### Крок 2: Встановлення Netdata

```bash
wget -O /tmp/netdata-kickstart.sh https://get.netdata.cloud/kickstart.sh && sh /tmp/netdata-kickstart.sh --stable-channel --disable-telemetry
```

#### Крок 3: Налаштування Master ноди

1. Згенеруйте API ключ:
   ```bash
   uuidgen
   ```

2. Налаштуйте `/etc/netdata/stream.conf`:
   ```ini
   [YOUR_API_KEY]
       enabled = yes
       allow from = 192.168.88.*
       default memory mode = save
       default history = 3600
       enable replication = yes
   ```

3. Перезапустіть Netdata:
   ```bash
   sudo systemctl restart netdata
   ```

#### Крок 4: Налаштування Worker нод

Налаштуйте `/etc/netdata/stream.conf`:
```ini
[stream]
    enabled = yes
    destination = 192.168.88.30:19999
    api key = YOUR_API_KEY
    timeout seconds = 60
    buffer size bytes = 10485760
    reconnect delay seconds = 5
```

## Ansible Playbooks

### Доступні Playbooks

1. **`setup-netdata.yml`** - Універсальний playbook (рекомендований)
2. **`setup-netdata-master.yml`** - Тільки для master ноди
3. **`setup-netdata-workers.yml`** - Тільки для worker нод

### Використання Playbooks

#### Варіант 1: Універсальний playbook

```bash
# Встановити на всіх нодах
ansible-playbook -i ../inventory/cluster.ini setup-netdata.yml

# Тільки master
ansible-playbook -i ../inventory/cluster.ini setup-netdata.yml --limit master

# Тільки workers
ansible-playbook -i ../inventory/cluster.ini setup-netdata.yml --limit workers
```

#### Варіант 2: Окремі playbooks

```bash
# 1. Спочатку master
ansible-playbook -i ../inventory/cluster.ini setup-netdata-master.yml

# 2. Потім workers з API ключем
ansible-playbook -i ../inventory/cluster.ini setup-netdata-workers.yml -e "netdata_api_key=YOUR_API_KEY"
```

### Змінні Ansible

#### Основні змінні

- `netdata_api_key` - API ключ для підключення workers до master
- `netdata_allow_from` - Дозволені IP адреси (за замовчуванням: `192.168.88.*`)
- `netdata_memory_mode` - Режим збереження даних (за замовчуванням: `save`)
- `netdata_history` - Час збереження історії в секундах (за замовчуванням: `3600`)

#### Змінні для workers

- `netdata_timeout` - Таймаут підключення (за замовчуванням: `60`)
- `netdata_buffer_size` - Розмір буфера (за замовчуванням: `10485760`)
- `netdata_reconnect_delay` - Затримка перепідключення (за замовчуванням: `5`)

### Приклад з кастомними змінними

```bash
ansible-playbook -i ../inventory/cluster.ini setup-netdata.yml \
  -e "netdata_api_key=your-custom-api-key" \
  -e "netdata_allow_from=192.168.1.*" \
  -e "netdata_history=7200"
```

## Доступ до дашборду

- **URL**: http://192.168.88.30:19999
- **Порт**: 19999
- **Доступ**: Відкритий для всіх в мережі 192.168.88.*

## Структура файлів

```
/etc/netdata/stream.conf  # Конфігурація стрімінгу
/usr/sbin/netdata        # Виконуваний файл Netdata
/var/log/netdata/        # Логи Netdata
```

## Моніторинг та діагностика

### Перевірка статусу сервісу

```bash
# Статус на всіх нодах
make netdata-status

# Статус на конкретній ноді
systemctl status netdata
```

### Перегляд логів

```bash
# Логи в реальному часі
journalctl -u netdata -f

# Логи з файлу
tail -f /var/log/netdata/error.log
```

### Перевірка конфігурації

```bash
# Тест конфігурації
netdata -t

# Перевірка портів
netstat -tlnp | grep 19999
```

### Ручне керування сервісом

```bash
# Перезапуск
sudo systemctl restart netdata

# Зупинка
sudo systemctl stop netdata

# Запуск
sudo systemctl start netdata

# Автозапуск
sudo systemctl enable netdata
```

## Troubleshooting

### Проблема: Worker не підключається до master

**Рішення:**
1. Перевірте API ключ в `/etc/netdata/stream.conf`
2. Перевірте доступність master ноди: `ping 192.168.88.30`
3. Перевірте порт: `telnet 192.168.88.30 19999`
4. Перезапустіть Netdata на worker: `sudo systemctl restart netdata`

### Проблема: Master не приймає підключення

**Рішення:**
1. Перевірте конфігурацію в `/etc/netdata/stream.conf`
2. Перевірте, що API ключ правильно налаштований
3. Перевірте firewall: `sudo ufw status`
4. Перезапустіть Netdata: `sudo systemctl restart netdata`

### Проблема: Високе навантаження на CPU

**Рішення:**
1. Зменшіть інтервал збору метрик
2. Вимкніть непотрібні плагіни
3. Налаштуйте обмеження пам'яті

### Проблема: Нода не з'являється в дашборді

**Рішення:**
1. Перевірте статус Netdata на ноді
2. Перевірте логи на помилки
3. Перевірте мережеве підключення
4. Перезапустіть Netdata на обох нодах

## Налаштування безпеки

### Обмеження доступу

```ini
# В /etc/netdata/stream.conf на master
[API_KEY]
    enabled = yes
    allow from = 192.168.88.0/24  # Тільки локальна мережа
    default memory mode = save
    default history = 3600
    enable replication = yes
```

### Firewall налаштування

```bash
# Дозволити тільки локальну мережу
sudo ufw allow from 192.168.88.0/24 to any port 19999
```

## Оптимізація

### Налаштування пам'яті

```ini
# В /etc/netdata/netdata.conf
[global]
    memory mode = save
    history = 3600
    update every = 1
```

### Налаштування мережі

```ini
# В /etc/netdata/stream.conf на workers
[stream]
    enabled = yes
    destination = 192.168.88.30:19999
    api key = YOUR_API_KEY
    timeout seconds = 30
    buffer size bytes = 5242880
    reconnect delay seconds = 3
```

## Оновлення

### Оновлення Netdata

```bash
# Автоматичне оновлення
sudo netdata-updater.sh

# Ручне оновлення
wget -O /tmp/netdata-kickstart.sh https://get.netdata.cloud/kickstart.sh
sudo sh /tmp/netdata-kickstart.sh --stable-channel --disable-telemetry
```

## Примітки

- Playbooks розраховані на Ubuntu 24.04
- Автоматично встановлюються всі необхідні залежності
- Телеметрія Netdata відключена (`--disable-telemetry`)
- Використовується стабільний канал (`--stable-channel`)
- Порт 19999 відкритий для локальної мережі
- API ключ генерується автоматично для master ноди

## Корисні посилання

- [Офіційна документація Netdata](https://learn.netdata.cloud/)
- [Netdata Cloud](https://app.netdata.cloud/)
- [GitHub репозиторій](https://github.com/netdata/netdata)
