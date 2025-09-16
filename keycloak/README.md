# Keycloak Kubernetes Manifests

Цей каталог містить Kubernetes маніфести для розгортання Keycloak з PostgreSQL в кластері K3s.

## Структура файлів

1. `01-namespace.yaml` - Namespace для Keycloak
2. `02-postgres-pvc.yaml` - PersistentVolumeClaim для PostgreSQL
3. `03-postgres-deployment.yaml` - PostgreSQL Deployment
4. `04-postgres-service.yaml` - PostgreSQL Service
5. `05-keycloak-discovery-service.yaml` - Keycloak Discovery Service (Headless)
6. `06-keycloak-service.yaml` - Keycloak Service
7. `07-keycloak-statefulset.yaml` - Keycloak StatefulSet
8. `08-keycloak-ingress.yaml` - Keycloak Ingress
9. `09-keycloak-realm-config.yaml` - ConfigMap з конфігурацією realm "test"
10. `10-keycloak-test-realm-job.yaml` - Job для створення realm "test"
11. `11-keycloak-test-user-job.yaml` - Job для створення тестового користувача

## Розгортання

### 1. Застосування основних маніфестів

```bash
# Застосувати всі маніфести в правильному порядку
kubectl apply -f keycloak/
```

### 2. Очікування готовності Keycloak

```bash
# Перевірити статус StatefulSet
kubectl get statefulset -n keycloak

# Перевірити логи Keycloak
kubectl logs -n keycloak statefulset/keycloak -f
```

### 3. Створення realm та користувачів

```bash
# Застосувати Job для створення realm "test"
kubectl apply -f keycloak/10-keycloak-test-realm-job.yaml

# Перевірити логи Job
kubectl logs -n keycloak job/keycloak-test-realm-create -f

# Застосувати Job для створення тестового користувача
kubectl apply -f keycloak/11-keycloak-test-user-job.yaml

# Перевірити логи Job
kubectl logs -n keycloak job/keycloak-test-user-create -f
```

## Доступ до Keycloak

### Внутрішній доступ (всередині кластера)
- Service: `http://keycloak.keycloak.svc.cluster.local:8080`
- Admin Console: `http://keycloak.keycloak.svc.cluster.local:8080/admin`

### Зовнішній доступ
- URL: `http://auth.k3s-test.local`
- Admin Console: `http://auth.k3s-test.local/admin`

### Облікові дані
- **Admin користувач**: `admin` / `admin`
- **Тестовий користувач**: `testuser` / `testpass123`

## Конфігурація

### Realm "test"
- Назва: `test`
- Клієнт: `krakend` (для KrakenD API Gateway)
- Секрет клієнта: `krakend-secret-123`

### KrakenD клієнт
- `clientId`: `krakend`
- `directAccessGrantsEnabled`: `true`
- `serviceAccountsEnabled`: `true`
- `audience`: `krakend-test`

### Protocol Mappers
- `audience-mapper`: додає `krakend-test` до audience
- `username-mapper`: мапить `username` → `preferred_username`
- `realm-roles-mapper`: мапить `realm_access.roles`

## Тестування

### Отримання токена для тестового користувача

```bash
# Через port-forward
kubectl port-forward -n keycloak svc/keycloak 8080:8080 &

# Отримати токен
curl -X POST "http://localhost:8080/realms/test/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=testuser" \
  -d "password=testpass123" \
  -d "grant_type=password" \
  -d "client_id=krakend" \
  -d "client_secret=krakend-secret-123"
```

### Тестування з KrakenD

```bash
# Використати отриманий токен для доступу до protected endpoint
curl -H "Authorization: Bearer <TOKEN>" \
  "http://krakend-bff.krakend-lab.svc.cluster.local/api/v1/protected"
```

## Видалення

```bash
# Видалити всі ресурси
kubectl delete -f keycloak/
```

## Примітки

- PostgreSQL використовує PersistentVolumeClaim для збереження даних
- Keycloak налаштований для роботи з PostgreSQL
- Всі секрети та паролі захардкоджені для простоти (в продакшені використовуйте Kubernetes Secrets)
- Jobs для створення realm та користувачів можуть виконуватися кілька разів без проблем

