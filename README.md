# PI K3s Cluster

Цей репозиторій — пісочниця для побудови кластеру на базі Raspberry Pi з використанням [k3s](https://k3s.io/) — легкого дистрибутиву Kubernetes.

> Основна мета — погратися з автоматизацією.

---

## Структура

- [Інструкція з розгортання кластеру](/doc/setup.md)
- [Ansible-плейбуки для початкового налаштування](/doc/ansible.md)
- [ТУТ БУДЕ Terraform для управління інфраструктурою](/doc/terraform.md)
- [Пояснення стадій `stage`](/doc/stage.md)
- [Налаштування Vault](/doc/vault.md)

---

## Компоненти кластеру

- 1× master-node (Pi 5)
- 2× worker-node (Pi 5 / Pi 4)
- Kubernetes з Ingress NGINX (traefik вимкнено)
- Сертифікати через Cert-Manager
- HashiCorp Vault з auto-unseal
- Моніторинг: Prometheus + Grafana
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

```make
setup-base:
	cd ansible && ansible-playbook -i inventory/pi-cluster.ini playbooks/setup-base.yml

setup-k3s:
	cd ansible && ansible-playbook -i inventory/pi-cluster.ini playbooks/setup-k3s.yml

apply:
	cd terraform && terraform apply -auto-approve

destroy:
	cd terraform && terraform destroy -auto-approve
```

### Посилання:
- [k3s](https://k3s.io/) — легкий дистрибутив Kubernetes, який ідеально підходить для Raspberry Pi.

### Ліцензія:
MIT — роби з цим що хочеш.