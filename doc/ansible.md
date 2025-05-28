# K3s Raspberry Pi Cluster Provisioning with Ansible

Автоматизація розгортання кластеру K3s на Raspberry Pi (1 master + N worker'ів) за допомогою Ansible.

## Структура

```
ansible/
├── ansible.cfg                 # Конфігурація Ansible
├── inventory/
│   └── pi-cluster.ini          # Інвентар хостів (master і worker-и)
└── playbooks/
    ├── setup-base.yml          # Підготовка системи (hostname, swap, cgroups, iptables)
    └── setup-k3s.yml           # Встановлення K3s на master і worker'и
```

## Інвентар

Файл `ansible/inventory/pi-cluster.ini`:

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
kube_context_name=pi-k3s-cluster
```

## Вимоги

- Raspberry Pi з Raspberry Pi OS (Lite або Full)
- Ansible ≥ 2.10
- kubectl встановлений локально для управління кластером
- Наявність SSH ключа, який дозволяє підключення без пароля, та додано до ssh

## Інструкція використання

### Крок 1 — Підготовка системи

```bash
ansible-playbook -i inventory/pi-cluster.ini playbooks/setup-base.yml
```

Цей плейбук:
- Оновлює систему
- Встановлює hostname
- Встановлює iptables
- Вимикає та видаляє swap
- Додає cgroup параметри в `/boot/firmware/cmdline.txt`
- Перезавантажує Pi за потреби

### Крок 2 — Встановлення K3s

```bash
ansible-playbook -i inventory/pi-cluster.ini playbooks/setup-k3s.yml
```

Цей плейбук:
- Встановлює K3s master (без Traefik)
- Встановлює K3s на worker'и з підключенням до master
- Копіює kubeconfig локально та об'єднує з існуючим у `~/.kube/config`

## Перевірка кластеру

```bash
kubectl get nodes
```

## Видалення кластеру (опціонально)

На будь-якому Pi:

```bash
sudo /usr/local/bin/k3s-uninstall.sh
```