ANSIBLE_INV=inventory/cluster.ini
ANSIBLE_DIR=ansible
TERRAFORM_DIR=terraform

.PHONY: setup-ubuntu setup-influxdb setup-telegraf setup-dashboards setup-k3s setup-netdata setup-netdata-master setup-netdata-workers test-connection copy-config copy-secrets setup-cluster-access cluster-status netdata-status upgrade-ubuntu upgrade-ubuntu-safe upgrade-security plan apply destroy full help

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

setup-netdata-master:
	@echo "Setting up Netdata master node..."
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(ANSIBLE_INV) playbooks/setup-netdata.yml --limit master

setup-netdata-workers:
	@echo "Setting up Netdata worker nodes..."
	@echo "Note: This requires the API key from master. Run 'make setup-netdata-master' first."
	@read -p "Enter the API key from master: " api_key; \
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(ANSIBLE_INV) playbooks/setup-netdata.yml --limit workers -e "netdata_api_key=$$api_key"

setup-netdata:
	@echo "Setting up Netdata on all nodes (master + workers)..."
	@echo "Step 1: Setting up master node..."
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(ANSIBLE_INV) playbooks/setup-netdata.yml --limit master
	@echo "Step 2: Getting API key from master..."
	@api_key=$$(cd $(ANSIBLE_DIR) && ansible ser0 -i $(ANSIBLE_INV) -m shell -a "grep -o '[a-f0-9-]\{36\}' /etc/netdata/stream.conf | head -1" | grep -o '[a-f0-9-]\{36\}'); \
	echo "API Key: $$api_key"; \
	echo "Step 3: Setting up worker nodes..."; \
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(ANSIBLE_INV) playbooks/setup-netdata.yml --limit workers -e "netdata_api_key=$$api_key"

test-connection:
	@echo "Testing SSH connection to all nodes..."
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(ANSIBLE_INV) playbooks/test-connection.yml

# Cluster configuration management
copy-config:
	@echo "Copying cluster kubeconfig to local machine..."
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(ANSIBLE_INV) playbooks/copy-cluster-config.yml

copy-secrets:
	@echo "Copying cluster secrets and certificates to local machine..."
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(ANSIBLE_INV) playbooks/copy-cluster-secrets.yml

setup-cluster-access:
	@echo "Setting up complete cluster access (config + secrets)..."
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(ANSIBLE_INV) playbooks/setup-cluster-access.yml

cluster-status:
	@echo "Checking cluster status..."
	kubectl --context=local-k3s get nodes
	kubectl --context=local-k3s get pods --all-namespaces

netdata-status:
	@echo "Checking Netdata status on all nodes..."
	cd $(ANSIBLE_DIR) && ansible ser -i $(ANSIBLE_INV) -m shell -a "systemctl is-active netdata"
	@echo ""
	@echo "Netdata dashboard: http://192.168.88.30:19999"

# System upgrade management
upgrade-ubuntu:
	@echo "Upgrading Ubuntu system packages on all nodes..."
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(ANSIBLE_INV) playbooks/upgrade-ubuntu.yml

upgrade-ubuntu-safe:
	@echo "Performing safe Ubuntu upgrade with pre/post checks..."
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(ANSIBLE_INV) playbooks/upgrade-ubuntu-safe.yml

upgrade-security:
	@echo "Installing security updates only..."
	cd $(ANSIBLE_DIR) && ansible-playbook -i $(ANSIBLE_INV) playbooks/upgrade-security.yml

plan:
	@echo "Running terraform plan..."
	cd $(TERRAFORM_DIR) && terraform plan

apply:
	@echo "Applying terraform configuration..."
	cd $(TERRAFORM_DIR) && terraform apply -auto-approve

destroy:
	@echo "Destroying infrastructure (only safe with stage=1)..."
	@if [ "$$(jq -r .stage $(TERRAFORM_DIR)/scripts/stage.json)" != "1" ]; then \
		echo "You must set stage=1 in scripts/stage.json before destroying."; \
		exit 1; \
	fi
	cd $(TERRAFORM_DIR) && terraform destroy -auto-approve

full: setup-ubuntu setup-influxdb setup-telegraf setup-dashboards setup-k3s setup-netdata setup-cluster-access apply

help:
	@echo "Available commands:"
	@echo "  setup-ubuntu          - Setup Ubuntu 24 on all nodes"
	@echo "  setup-influxdb        - Install InfluxDB on master"
	@echo "  setup-telegraf        - Setup Telegraf monitoring"
	@echo "  setup-dashboards      - Import InfluxDB dashboards"
	@echo "  setup-k3s             - Install K3s cluster"
	@echo "  setup-netdata         - Setup Netdata monitoring (all nodes)"
	@echo "  setup-netdata-master  - Setup Netdata master only"
	@echo "  setup-netdata-workers - Setup Netdata workers only"
	@echo "  netdata-status        - Check Netdata status"
	@echo "  cluster-status        - Check cluster status"
	@echo "  test-connection       - Test SSH connections"
	@echo "  full                  - Run complete setup"
	@echo ""
	@echo "Netdata dashboard: http://192.168.88.30:19999"