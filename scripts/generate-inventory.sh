#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

VM_IP=$(terraform -chdir="$ROOT_DIR/terraform/vm" output -raw vm_ip)
VM_USER=$(terraform -chdir="$ROOT_DIR/terraform/vm" output -raw vm_user)

SSH_KEY="$HOME/.ssh/cloudtask_ed25519"
KNOWN_HOSTS="$ROOT_DIR/.runtime/known_hosts"

mkdir -p "$ROOT_DIR/.runtime"

cat > "$ROOT_DIR/ansible/inventory.ini" <<EOF
[cloudtask]
cloudtask-server ansible_host=$VM_IP

[cloudtask:vars]
ansible_user=$VM_USER
ansible_ssh_private_key_file=$SSH_KEY
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=$KNOWN_HOSTS'
EOF

echo "Inventory generated successfully."
echo "Server IP: $VM_IP"