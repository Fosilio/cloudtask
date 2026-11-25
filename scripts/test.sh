#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

VM_IP=$(terraform -chdir="$ROOT_DIR/terraform/vm" output -raw vm_ip)
VM_USER=$(terraform -chdir="$ROOT_DIR/terraform/vm" output -raw vm_user)

SSH_KEY="$HOME/.ssh/cloudtask_ed25519"

echo "========================================"
echo "       CLOUDTASK AUTOMATED TESTS"
echo "========================================"

echo
echo "=== APPLICATION HEALTH ==="

curl -fsS \
    --resolve "frontend.cloudtask.test:80:$VM_IP" \
    http://frontend.cloudtask.test/api/health

echo

echo
echo "=== DNS TESTS ==="

bash "$ROOT_DIR/tests/dns.sh" "$VM_IP"

echo
echo "=== NETWORK ISOLATION TESTS ==="

ssh -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile="$ROOT_DIR/.runtime/known_hosts" -i "$SSH_KEY" "$VM_USER@$VM_IP" \
    "sudo bash -s" < "$ROOT_DIR/tests/network.sh"

echo
echo "=== DATABASE PERSISTENCE TESTS ==="

ssh -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile="$ROOT_DIR/.runtime/known_hosts" -i "$SSH_KEY" "$VM_USER@$VM_IP" \
    "sudo bash -s" < "$ROOT_DIR/tests/persistence.sh"

echo
echo "========================================"
echo "          ALL TESTS PASSED"
echo "========================================"