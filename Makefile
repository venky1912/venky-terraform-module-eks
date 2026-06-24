.PHONY: init fmt validate lint scan docs plan clean all

init:
	terraform init -backend=false

fmt:
	terraform fmt -recursive

validate: init
	terraform validate

lint:
	tflint --init
	tflint --format compact

scan:
	docker run --rm -v "$(PWD):/src" aquasec/trivy config --severity MEDIUM,HIGH,CRITICAL /src
	docker run --rm -v "$(PWD):/tf" bridgecrew/checkov -d /tf --framework terraform --quiet

docs:
	terraform-docs .

plan: init
	cd examples/complete && terraform init -backend=false && terraform validate

all: fmt validate lint docs

clean:
	rm -rf .terraform .terraform.lock.hcl
	rm -rf examples/complete/.terraform examples/complete/.terraform.lock.hcl
