apply:
	cd terraform && terraform apply -auto-approve -var="stage=1"
	cd terraform && terraform apply -auto-approve -var="stage=2"

destroy:
	cd terraform && terraform apply -auto-approve -var="stage=1"
	cd terraform && terraform destroy -auto-approve -var="stage=1"