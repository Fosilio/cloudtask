#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

VM_IP=$(terraform -chdir="$ROOT_DIR/terraform/vm" output -raw vm_ip)
VM_USER=$(terraform -chdir="$ROOT_DIR/terraform/vm" output -raw vm_user)

SSH_KEY="$HOME/.ssh/cloudtask_ed25519"

echo "=== TSIG PERMISSIONS TEST ==="

echo "[TEST 1] Valid key attempting TXT update"

RC=0

RESULT=$(ssh -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile="$ROOT_DIR/.runtime/known_hosts" -i "$SSH_KEY" "$VM_USER@$VM_IP" \
    "sudo nsupdate -k /etc/bind/cloudtask.key" 2>&1 <<EOF
server 127.0.0.1
zone cloudtask.test.
update add tsig-test.cloudtask.test. 300 TXT "forbidden"
send
EOF
) || RC=$?

echo "$RESULT"

if [ "$RC" -eq 0 ] || ! grep -q 'REFUSED' <<< "$RESULT"; then
    echo "[FAIL] Expected REFUSED response."
    exit 1
fi

echo "[PASS] TSIG key cannot modify TXT records."

echo "[TEST 2] Valid key attempting update outside project zone"

RC=0

RESULT=$(ssh -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile="$ROOT_DIR/.runtime/known_hosts" -i "$SSH_KEY" "$VM_USER@$VM_IP" \
    "sudo nsupdate -k /etc/bind/cloudtask.key" 2>&1 <<EOF
server 127.0.0.1
zone example.test.
update add tsig-test.example.test. 300 A 192.0.2.10
send
EOF
) || RC=$?

echo "$RESULT"

if [ "$RC" -eq 0 ] || ! grep -Eq 'REFUSED|NOTAUTH|NOTZONE' <<< "$RESULT"; then
    echo "[FAIL] Expected rejection outside project zone."
    exit 1
fi

echo "[PASS] Update outside project zone rejected."

echo "=== TSIG PERMISSIONS TEST PASSED ==="