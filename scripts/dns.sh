#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export TF_VAR_dns_server
TF_VAR_dns_server=$(terraform -chdir="$ROOT_DIR/terraform/vm" output -raw vm_ip)

export TF_VAR_tsig_secret
TF_VAR_tsig_secret=$(cat "$ROOT_DIR/.secrets/tsig_secret")

terraform -chdir="$ROOT_DIR/terraform/dns" "$@"