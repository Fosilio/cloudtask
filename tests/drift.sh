#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

VM_IP=$(terraform -chdir="$ROOT_DIR/terraform/vm" output -raw vm_ip)
VM_USER=$(terraform -chdir="$ROOT_DIR/terraform/vm" output -raw vm_user)

SSH_KEY="$HOME/.ssh/cloudtask_ed25519"

echo "=== TERRAFORM DNS DRIFT DEMONSTRATION ==="

echo "[1] Original DNS record"

dig @"$VM_IP" backend.cloudtask.test A +short

echo "[2] Introducing infrastructure drift"

ssh -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile="$ROOT_DIR/.runtime/known_hosts" -i "$SSH_KEY" "$VM_USER@$VM_IP" \
    "sudo nsupdate -k /etc/bind/cloudtask.key" <<EOF
server 127.0.0.1
zone cloudtask.test.
update delete backend.cloudtask.test. A
update add backend.cloudtask.test. 300 A 172.20.20.99
send
EOF

echo "[3] Modified DNS record"

dig @"$VM_IP" backend.cloudtask.test A +short

echo "[4] Terraform detects drift"

PLAN_RC=0

"$ROOT_DIR/scripts/dns.sh" plan -detailed-exitcode || PLAN_RC=$?

if [ "$PLAN_RC" -ne 2 ]; then
    echo "[FAIL] Expected Terraform drift detection."
    exit 1
fi

echo "[PASS] Infrastructure drift detected."

echo "[5] Terraform restores desired state"

"$ROOT_DIR/scripts/dns.sh" apply -auto-approve

echo "[6] Verify restored DNS record"

ACTUAL=$(dig @"$VM_IP" backend.cloudtask.test A +short)

if [ "$ACTUAL" != "172.20.20.20" ]; then
    echo "[FAIL] DNS record was not restored."
    exit 1
fi

echo "[PASS] Original DNS record restored: $ACTUAL"

echo "[7] Final Terraform plan"

"$ROOT_DIR/scripts/dns.sh" plan -detailed-exitcode

echo "=== DRIFT DEMONSTRATION PASSED ==="