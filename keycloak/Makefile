# Keycloak Kubernetes Manifests Makefile

.PHONY: help apply delete status logs clean test

# Default target
help:
	@echo "Available targets:"
	@echo "  apply    - Apply all Keycloak manifests"
	@echo "  delete   - Delete all Keycloak resources"
	@echo "  status   - Show status of Keycloak resources"
	@echo "  logs     - Show Keycloak logs"
	@echo "  clean    - Clean up completed jobs"
	@echo "  test     - Test Keycloak connectivity"
	@echo "  realm    - Create rakia realm"
	@echo "  user     - Create test user"

# Apply all manifests
apply:
	@echo "Applying Keycloak manifests..."
	kubectl apply -f 01-namespace.yaml
	kubectl apply -f 02-postgres-pvc.yaml
	kubectl apply -f 03-postgres-deployment.yaml
	kubectl apply -f 04-postgres-service.yaml
	kubectl apply -f 05-keycloak-discovery-service.yaml
	kubectl apply -f 06-keycloak-service.yaml
	kubectl apply -f 07-keycloak-statefulset.yaml
	kubectl apply -f 08-keycloak-ingress.yaml
	kubectl apply -f 09-keycloak-realm-config.yaml
	@echo "Keycloak manifests applied successfully!"

# Delete all resources
delete:
	@echo "Deleting Keycloak resources..."
	kubectl delete -f . --ignore-not-found=true
	@echo "Keycloak resources deleted!"

# Show status
status:
	@echo "=== Keycloak Namespace ==="
	kubectl get namespace keycloak
	@echo ""
	@echo "=== Keycloak StatefulSet ==="
	kubectl get statefulset -n keycloak
	@echo ""
	@echo "=== Keycloak Pods ==="
	kubectl get pods -n keycloak
	@echo ""
	@echo "=== Keycloak Services ==="
	kubectl get svc -n keycloak
	@echo ""
	@echo "=== Keycloak Jobs ==="
	kubectl get jobs -n keycloak

# Show logs
logs:
	@echo "Showing Keycloak logs..."
	kubectl logs -n keycloak statefulset/keycloak -f

# Clean up completed jobs
clean:
	@echo "Cleaning up completed jobs..."
	kubectl delete jobs -n keycloak --field-selector status.successful=1 --ignore-not-found=true
	@echo "Completed jobs cleaned up!"

# Create rakia realm
realm:
	@echo "Creating rakia realm..."
	kubectl apply -f 10-keycloak-rakia-realm-job.yaml
	@echo "Realm creation job started. Check logs with: make realm-logs"

# Create test user
user:
	@echo "Creating test user..."
	kubectl apply -f 11-keycloak-test-user-job.yaml
	@echo "Test user creation job started. Check logs with: make user-logs"

# Show realm creation logs
realm-logs:
	kubectl logs -n keycloak job/keycloak-rakia-realm-create -f

# Show user creation logs
user-logs:
	kubectl logs -n keycloak job/keycloak-test-user-create -f

# Test connectivity
test:
	@echo "Testing Keycloak connectivity..."
	@echo "Waiting for Keycloak to be ready..."
	@timeout 60 bash -c 'until kubectl get pods -n keycloak -l app=keycloak --no-headers | grep Running; do sleep 2; done'
	@echo "Keycloak is ready!"
	@echo "Testing internal connectivity..."
	kubectl run test-curl --image=curlimages/curl --rm -it --restart=Never -- curl -s http://keycloak.keycloak.svc.cluster.local:8080/realms/master | head -c 100
	@echo ""
	@echo "Keycloak is accessible!"

# Wait for Keycloak to be ready
wait:
	@echo "Waiting for Keycloak to be ready..."
	@timeout 300 bash -c 'until kubectl get pods -n keycloak -l app=keycloak --no-headers | grep Running; do sleep 5; done'
	@echo "Keycloak is ready!"

# Full deployment
deploy: apply wait realm user
	@echo "Keycloak deployment completed!"
	@echo "Access Keycloak at: http://auth.k3s-rakia.local"
	@echo "Admin credentials: admin/admin"
	@echo "Test user: testuser/testpass123"

