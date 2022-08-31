#!/usr/bin/env make

CMD_COMPOSE ?= docker compose

#: Initialise the terraform workspace.
init: .terraform.lock.hcl
.terraform.lock.hcl: \
		_main.tf \
		docker-compose.yml
	${CMD_COMPOSE} run \
	terraform init \
		--backend=false

#: Validate the terraform code.
validate: tests/validation.done
tests/validation.done: \
		.terraform.lock.hcl \
		docker-compose.yml
	${CMD_COMPOSE} run \
	terraform validate && \
	touch ${@}

#: Run tests against the code.
test: tests/junit.xml
tests/junit.xml: \
		$(wildcard *.tf) \
		$(wildcard tests/*/*.tf) \
		docker-compose.yml
	${CMD_COMPOSE} run \
	terraform test \
		--junit-xml=/app/${@}

#: Generate terraform documentation
docs: terraform.adoc
terraform.adoc: \
		$(wildcard *.tf) \
		.terraform-docs.yml \
		docker-compose.yml
	${CMD_COMPOSE} run \
	terraform-docs asciidoc table \
		--header-from _main.tf \
		--output-file ${@} \
		--output-mode replace \
		--hide-empty \
		.
