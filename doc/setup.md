# Розгортання K3s кластера

Повна інструкція з розгортання K3s кластера з автоматизацією через Ansible та управлінням інфраструктурою через Terraform.

> Цей документ описує як вручну налаштувати кластер. Для автоматизованого розгортання використовуйте [Ansible playbooks](/doc/ansible.md).

---

## Передумови

### Апаратні вимоги

**Master Node:**
- CPU: 2+ ядра
- RAM: 4+ GB
- Storage: 20+ GB
- Network: стабільне підключення

**Worker Nodes:**
- CPU: 2+ ядра
- RAM: 4+ GB
- Storage: 20+ GB
- Network: стабільне підключення

### Програмне забезпечення

- Ubuntu 24.04 LTS Server (або сумісний дистрибутив)
- SSH доступ
- Статичні IP адреси
- Мережева доступність між нодами

---

## Крок 1: Підготовка нодів

### Встановлення операційної системи

1. **Завантажте Ubuntu Server ISO:**
   ```bash
   wget https://releases.ubuntu.com/24.04/ubuntu-24.04-lts-server-amd64.iso
   ```

2. **Створіть завантажувальний носій:**
   ```bash
   # Використовуючи dd
   sudo dd if=ubuntu-24.04-lts-server-amd64.iso of=/dev/sdX bs=4M status=progress
   
   # Або використовуючи balenaEtcher, Rufus тощо
   ```

3. **Встановіть Ubuntu на кожну ноду:**
   - Виберіть мінімальну установку
   - Налаштуйте статичні IP адреси
   - Створіть користувача з sudo правами
   - Увімкніть SSH

### Налаштування мережі

**Приклад конфігурації `/etc/netplan/00-installer-config.yaml`:**

```yaml
network:
  version: 2
  ethernets:
    enp1s0:  # або eno1, eth0 залежно від сервера
      dhcp4: false
      addresses:
        - 192.168.88.30/24  # Master
        # - 192.168.88.31/24  # Worker 1
        # - 192.168.88.32/24  # Worker 2
        # - 192.168.88.33/24  # Worker 3
        # - 192.168.88.34/24  # Worker 4
      gateway4: 192.168.88.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 1.1.1.1
```

Застосуйте зміни:
```bash
sudo netplan apply
```

---

## Крок 2: Підготовка SSH ключів

### Генерація SSH ключа

```bash
ssh-keygen -t ed25519 -C "k3s-cluster"
```

### Копіювання ключа на ноди

```bash
# Для кожної ноди
ssh-copy-id -i ~/.ssh/k3s.pub k3s@192.168.88.30
ssh-copy-id -i ~/.ssh/k3s.pub k3s@192.168.88.31
ssh-copy-id -i ~/.ssh/k3s.pub k3s@192.168.88.32
ssh-copy-id -i ~/.ssh/k3s.pub k3s@192.168.88.33
ssh-copy-id -i ~/.ssh/k3s.pub k3s@192.168.88.34
```

---

## Крок 3: Налаштування Ansible

### Встановлення Ansible

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install ansible

# Або через pip
pip3 install ansible
```

### Налаштування inventory

Створіть файл `ansible/inventory/cluster.ini`:

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

---

## Крок 4: Автоматизоване розгортання

### Використання Ansible playbooks

```bash
# Підготовка системи
ansible-playbook -i inventory/cluster.ini playbooks/setup-ubuntu.yml

# Встановлення K3s
ansible-playbook -i inventory/cluster.ini playbooks/setup-k3s.yml

# Налаштування моніторингу
ansible-playbook -i inventory/cluster.ini playbooks/setup-influxdb.yml
ansible-playbook -i inventory/cluster.ini playbooks/setup-telegraf.yml

# Копіювання конфігурації
ansible-playbook -i inventory/cluster.ini playbooks/copy-cluster-config.yml
```

### Використання Makefile

```bash
# Повне розгортання
make setup-all

# Окремі компоненти
make setup-ubuntu
make setup-k3s
make setup-monitoring
```

---

## Крок 5: Перевірка кластера

### Перевірка статусу нодів

```bash
kubectl get nodes -o wide
```

### Перевірка подів

```bash
kubectl get pods --all-namespaces
```

### Перевірка сервісів

```bash
kubectl get services --all-namespaces
```

---

## Крок 6: Налаштування доступу

### Копіювання kubeconfig

```bash
ansible-playbook -i inventory/cluster.ini playbooks/copy-cluster-config.yml
```

### Налаштування kubectl

```bash
export KUBECONFIG=~/.kube/k3s-cluster
kubectl config use-context k3s-cluster
```

---

## Troubleshooting

### Проблеми з мережею

```bash
# Перевірка підключення
ping 192.168.88.30
telnet 192.168.88.30 6443

# Перевірка firewall
sudo ufw status
sudo ufw allow 6443
```

### Проблеми з K3s

```bash
# Перевірка логів
sudo journalctl -u k3s -f

# Перезапуск сервісу
sudo systemctl restart k3s
```

### Проблеми з Ansible

```bash
# Тест підключення
ansible all -i inventory/cluster.ini -m ping

# Детальний вивід
ansible-playbook -i inventory/cluster.ini playbooks/setup-k3s.yml -vvv
```

---

## Наступні кроки

1. **Налаштування моніторингу** - [Telegraf + InfluxDB](/doc/telegraf.md)
2. **Налаштування додатків** - [Terraform modules](/terraform/)
3. **Безпека** - [Vault setup](/doc/vault.md)
4. **Troubleshooting** - [Common issues](/doc/troubleshooting.md)

---

## Корисні посилання

- [K3s Documentation](https://k3s.io/)
- [Ansible Documentation](https://docs.ansible.com/)
- [Ubuntu Server Guide](https://ubuntu.com/server/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)