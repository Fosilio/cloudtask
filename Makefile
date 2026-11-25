SHELL := /bin/bash

.DEFAULT_GOAL := all

.PHONY: all check infra config dns deploy test drift tsig destroy tunnel

all:
	$(MAKE) check
	$(MAKE) infra
	$(MAKE) config
	$(MAKE) dns
	$(MAKE) deploy

check:
	bash scripts/bootstrap.sh

infra:
	terraform -chdir=terraform/vm init
	terraform -chdir=terraform/vm apply -auto-approve
	bash scripts/generate-inventory.sh

config:
	bash scripts/wait-for-server.sh
	cd ansible && ansible-playbook site.yml

dns:
	bash scripts/dns.sh init
	bash scripts/dns.sh apply -auto-approve

deploy:
	cd ansible && ansible-playbook deploy.yml

test:
	bash scripts/test.sh
	bash tests/tsig.sh

drift:
	bash tests/drift.sh

tsig:
	bash tests/tsig.sh

destroy:
	@if [ -f terraform/dns/terraform.tfstate ]; then \
		bash scripts/dns.sh destroy -auto-approve; \
	fi
	terraform -chdir=terraform/vm destroy -auto-approve
	rm -f ansible/inventory.ini
	rm -f .runtime/known_hosts

tunnel:
	ssh -o StrictHostKeyChecking=accept-new \
	-o UserKnownHostsFile="$(CURDIR)/.runtime/known_hosts" \
	-i "$$HOME/.ssh/cloudtask_ed25519" \
	-o ExitOnForwardFailure=yes \
	-N -L 127.0.0.1:8080:127.0.0.1:80 \
	$$(terraform -chdir=terraform/vm output -raw vm_user)@$$(terraform -chdir=terraform/vm output -raw vm_ip)