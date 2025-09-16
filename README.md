# PI K3s Cluster

Цей репозиторій — пісочниця для побудови кластеру на базі Raspberry Pi з використанням [k3s](https://k3s.io/) — легкого дистрибутиву Kubernetes.

> Основна мета — погратися з автоматизацією.

---

## Структура

- [Інструкція з розгортання кластеру](/doc/setup.md)
- [Ansible-плейбуки для початкового налаштування](/doc/ansible.md)
- [Налаштування Netdata моніторингу](/doc/netdata.md)
- [Налаштування Telegraf](/doc/telegraf.md)
- [ТУТ БУДЕ Terraform для управління інфраструктурою](/doc/terraform.md)
- [Пояснення стадій `stage`](/doc/stage.md)
- [Налаштування Vault](/doc/vault.md)

---

## Компоненти кластеру

- 1× master-node (Pi 5)
- 4× worker-node (Pi 5 / Pi 4 / x86)
- Kubernetes з Ingress NGINX (traefik вимкнено)
- Сертифікати через Cert-Manager
- HashiCorp Vault з auto-unseal
- Моніторинг: Netdata + Telegraf + InfluxDB
- АргоCD для CD пайплайнів

---

## Принцип роботи `stage`

Кожен `stage` активує нові компоненти у кластері. Це дозволяє поступово вводити інфраструктуру в експлуатацію. Значення зберігається у `stage.json`.

- `stage = 1` — базові компоненти (ingress, cert-manager, redis, vault)
- `stage = 2` — vault config, monitoring, argo-cd
- Стейдж може бути автоматично оновлений через Terraform (`null_resource` + jq)

Докладніше — в [документі про stage](/doc/stage.md).

---

## Makefile

### Основні команди

```make
# Повне налаштування кластеру
make full

# Налаштування окремих компонентів
make setup-ubuntu          # Ubuntu 24 на всіх нодах
make setup-k3s             # K3s кластер
make setup-netdata         # Netdata моніторинг
make setup-telegraf        # Telegraf моніторинг
make setup-influxdb        # InfluxDB на master

# Перевірка статусу
make cluster-status         # Статус K3s кластеру
make netdata-status        # Статус Netdata
make test-connection       # Тест SSH з'єднань

# Terraform
make plan                  # Terraform plan
make apply                 # Terraform apply
make destroy               # Terraform destroy

# Допомога
make help                  # Показати всі команди
```

### Швидкий старт

```bash
# 1. Налаштування базової системи
make setup-ubuntu

# 2. Встановлення K3s
make setup-k3s

# 3. Налаштування моніторингу
make setup-netdata
make setup-telegraf

# 4. Розгортання інфраструктури
make apply
```

### Посилання:
- [k3s](https://k3s.io/) — легкий дистрибутив Kubernetes, який ідеально підходить для Raspberry Pi.

### Ліцензія:
MIT — роби з цим що хочеш.