ANSIBLE_INV=inventory/cluster.ini
ANSIBLE_DIR=ansible
TERRAFORM_DIR=terraform

.PHONY: setup-ubuntu setup-k3s setup-telegraf setup-influxdb plan apply destroy full

setup-ubuntu:
	@echo "Running Ubuntu 24 specific setup via Ansible..."
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(ANSIBLE_INV) playbooks/setup-ubuntu.yml

setup-k3s:
	@echo "Installing K3s on all nodes..."
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(ANSIBLE_INV) playbooks/setup-k3s.yml

setup-telegraf:
	@echo "Setting up Telegraf on all nodes..."
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(ANSIBLE_INV) playbooks/setup-telegraf.yml

setup-influxdb:
	@echo "Installing and configuring InfluxDB on master node..."
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(ANSIBLE_INV) playbooks/setup-influxdb.yml

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

full: setup-ubuntu setup-influxdb setup-k3s setup-telegraf apply