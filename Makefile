default: init plan apply

init:
	terraform init

plan:
	terraform plan -var "region=ap-southeast-1"

apply:
	terraform apply -var "region=ap-southeast-1" -auto-approve

destroy:
	terraform destroy -var "region=ap-southeast-1" -auto-approve