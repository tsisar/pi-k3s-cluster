ANSIBLE_INV=inventory/cluster.ini
ANSIBLE_DIR=ansible
TERRAFORM_DIR=terraform

.PHONY: setup-ubuntu setup-influxdb setup-telegraf setup-dashboards setup-k3s test-connection plan apply destroy full

setup-ubuntu:
	@echo "Step 1: Running Ubuntu 24 specific setup via Ansible..."
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(ANSIBLE_INV) playbooks/setup-ubuntu.yml

setup-influxdb:
	@echo "Step 2: Installing and configuring InfluxDB on master node..."
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(ANSIBLE_INV) playbooks/setup-influxdb.yml

setup-telegraf:
	@echo "Step 3: Setting up Telegraf monitoring on all nodes..."
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(ANSIBLE_INV) playbooks/setup-telegraf.yml

setup-dashboards:
	@echo "Step 4: Importing InfluxDB dashboards and templates..."
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(ANSIBLE_INV) playbooks/setup-dashboards.yml

setup-k3s:
	@echo "Step 5: Installing K3s cluster on all nodes..."
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(ANSIBLE_INV) playbooks/setup-k3s.yml

test-connection:
	@echo "Testing SSH connection to all nodes..."
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(ANSIBLE_INV) playbooks/test-connection.yml

plan:
	@echo "Running terraform plan..."
	cd $(TERRAFORM_DIR) && terraform plan

apply:
	@echo "Applying terraform configuration (stage=$$(jq -r .stage $(TERRAFORM_DIR)/scripts/stage.json))..."
	cd $(TERRAFORM_DIR) && terraform apply -auto-approve

destroy:
	@echo "Destroying infrastructure (only safe with stage=1)..."
	@if [ "$$(jq -r .stage $(TERRAFORM_DIR)/scripts/stage.json)" != "1" ]; then \
		echo "You must set stage=1 in scripts/stage.json before destroying."; \
		exit 1; \
	fi
	cd $(TERRAFORM_DIR) && terraform destroy -auto-approve

full: setup-ubuntu setup-influxdb setup-telegraf setup-dashboards setup-k3s apply