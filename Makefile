

init: .terraform.lock.hcl
.terraform.lock.hcl:
	terraform init


validate:
	terraform validate
