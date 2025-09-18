# Ansible Makefile for K3s Cluster Setup

.PHONY: help test update setup-ubuntu install-k3s copy-config setup-monitoring setup-crds all

help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

test: ## Test connection to all hosts
	ansible-playbook playbooks/00-test-connection.yml

upgrade: ## Upgrade Ubuntu system (based on upgrade_type variable)
	ansible-playbook playbooks/01-upgrade-ubuntu.yml

upgrade-normal: ## Normal Ubuntu upgrade
	ansible-playbook playbooks/01-upgrade-ubuntu.yml -e upgrade_type=normal

upgrade-security: ## Security Ubuntu upgrade
	ansible-playbook playbooks/01-upgrade-ubuntu.yml -e upgrade_type=security

upgrade-safe: ## Safe Ubuntu upgrade
	ansible-playbook playbooks/01-upgrade-ubuntu.yml -e upgrade_type=safe

upgrade-skip: ## Skip Ubuntu upgrade
	ansible-playbook playbooks/01-upgrade-ubuntu.yml -e upgrade_type=none

upgrade-no-packages: ## Upgrade without package updates
	ansible-playbook playbooks/01-upgrade-ubuntu.yml -e upgrade_include_packages=false

setup-ubuntu: ## Setup Ubuntu base configuration
	ansible-playbook playbooks/02-setup-ubuntu.yml

install-k3s: ## Install K3s cluster
	ansible-playbook playbooks/03-install-k3s.yml

label-nodes: ## Label K3s nodes with role and CPU type
	ansible-playbook playbooks/04-label-nodes.yml

copy-config: ## Copy cluster config to local machine
	ansible-playbook playbooks/05-copy-config.yml

setup-monitoring: ## Setup monitoring (based on monitoring_type variable)
	ansible-playbook playbooks/06-setup-monitoring.yml -e monitoring_type=$(shell grep '^monitoring_type:' group_vars/all.yml | cut -d'"' -f2)

setup-crds: ## Setup CRDs for Terraform
	ansible-playbook playbooks/07-setup-crds.yml

all: ## Run all steps in sequence
	ansible-playbook playbooks/site.yml

# Individual monitoring options
setup-netdata: ## Setup only Netdata monitoring
	ansible-playbook playbooks/05-setup-monitoring.yml -e monitoring_type=netdata


setup-both: ## Setup both Netdata and InfluxDB monitoring
	ansible-playbook playbooks/05-setup-monitoring.yml -e monitoring_type=both

# Utility targets
inventory: ## Show inventory
	ansible-inventory --list

ping: ## Ping all hosts
	ansible all -m ping

nodes: ## Show node labels
	kubectl get nodes -o custom-columns=NAME:.metadata.name,NODE-ROLE:.metadata.labels.node-role,NODE-TYPE:.metadata.labels.node-type
