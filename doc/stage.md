# Механізм `stage` в Terraform-інфраструктурі

Цей репозиторій використовує механізм `stage` для **поступового розгортання інфраструктури**, щоб уникнути складних залежностей і дозволити стабільну, контрольовану автоматизацію.

---

## Основна ідея

1. У файлі [`scripts/stage.json`](scripts/stage.json) зберігається поточний етап (`stage`) як `"1"`, `"2"` тощо.
2. Terraform читає це значення через `data "external"`, і воно потрапляє в `local.stage`.
3. У `locals.enabled_modules` визначено, які модулі активні на кожному етапі (`stage >= N`).
4. Після успішного виконання модулів етапу, спеціальний ресурс оновлює `stage.json`, збільшуючи стадію.
5. При наступному запуску `terraform apply`, автоматично активуються модулі наступного етапу.

---

## Структура

### 1. `stage.json`

```json
{
  "stage": "1"
}
```

### 2. `data.external` читає файл:

```hcl
data "external" "current_stage" {
  program = ["bash", "${path.module}/scripts/get_stage.sh"]
}
```

Скрипт `get_stage.sh`:

```bash
#!/usr/bin/env bash
cat "${BASH_SOURCE%/*}/stage.json"
```

### 3. Локальні змінні

```hcl
locals {
  stage = tonumber(data.external.current_stage.result.stage)

  enabled_modules = {
    ingress_nginx  = local.stage >= 1
    cert_manager   = local.stage >= 1
    redis          = local.stage >= 1
    vault          = local.stage >= 1
    cluster_issuer = local.stage >= 2
    vault_config   = local.stage >= 2
    monitoring     = local.stage >= 2
    argo_cd        = local.stage >= 2
  }
}
```

### 4. Активація модулів

```hcl
module "cert_manager" {
  source   = "./modules/cert-manager"
  for_each = local.enabled_modules.cert_manager ? { "enabled" = {} } : {}
}
```

### 5. Автоінкремент `stage` після успіху

```hcl
resource "null_resource" "bump_stage_to_2" {
  provisioner "local-exec" {
    command = "jq '.stage = \"2\"' ${path.module}/scripts/stage.json > ${path.module}/scripts/stage.tmp && mv ${path.module}/scripts/stage.tmp ${path.module}/scripts/stage.json"
  }

  triggers = {
    always_run = timestamp()
  }

  depends_on = [
    module.ingress_nginx,
    module.cert_manager,
    module.redis,
    module.vault
  ]
}
```

---

## Навіщо це потрібно

- **Безпечне поступове розгортання:** проблеми в одному з модулів не блокують все.
- **Прозорість:** зрозуміло, які етапи вже виконані.
- **Масштабованість:** легко додати `stage 3`, `stage 4` тощо.

---

---

# Destroy: Як правильно зносити інфраструктуру

Щоб **грамотно знести інфраструктуру**, потрібно виконати зворотний порядок дій — від вищого етапу до першого (`stage`) із фіксацією змін.

---

### Крок 1. Понижуємо stage вручну

Редагуємо `scripts/stage.json` та зменшуємо значення поля `stage`, наприклад:

```json
{
  "stage": "1"
}
```

---

### Крок 2. Застосовуємо `terraform apply`

Це оновлює конфігурацію з урахуванням того, що частина інфраструктури тепер **неактивна**. Terraform позначить відповідні ресурси до видалення.

```bash
terraform apply
```

Після цього Terraform видалить ресурси зі `stage >= 2`, бо вони більше не увійдуть у `enabled_modules`.

---

### Крок 3. Коли `stage = "1"` — запускаємо `terraform destroy`

```bash
terraform destroy
```

Це повністю видалить базові компоненти (`stage 1`): `vault`, `redis`, `cert-manager`, `ingress-nginx`, та DNS записи.

---

### Циклова стратегія

Цей підхід дозволяє:

- поетапно зносити інфраструктуру;
- перевіряти наслідки змін перед повним `destroy`;
- уникати несподіваного видалення важливих компонентів.

---

> ⚠️ Важливо: **ніколи не виконуй `terraform destroy` зі `stage > 1`**, інакше Terraform може спробувати видалити залежності в неправильному порядку.
---
