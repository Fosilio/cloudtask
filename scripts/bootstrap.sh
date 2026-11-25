#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== CLOUDTASK BOOTSTRAP ==="

for tool in terraform ansible ansible-playbook ansible-galaxy virsh git curl dig nsupdate ssh ssh-keygen openssl make python3; do

    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "[FAIL] Missing required tool: $tool"
        exit 1
    fi

    echo "[OK] $tool"

done

echo "Checking libvirt service"

sudo systemctl enable --now libvirtd

echo "Checking libvirt network"

if ! virsh -c qemu:///system net-info default >/dev/null 2>&1; then
    echo "[FAIL] Default libvirt network is missing."
    exit 1
fi

if LC_ALL=C virsh -c qemu:///system net-info default | grep -E '^Active:[[:space:]]+yes' >/dev/null; then
    echo "[OK] Default network is already active."
else
    virsh -c qemu:///system net-start default
fi

virsh -c qemu:///system net-autostart default

echo "Checking libvirt storage pool"

if ! virsh -c qemu:///system pool-info default >/dev/null 2>&1; then

    sudo mkdir -p /var/lib/libvirt/images

    virsh -c qemu:///system pool-define-as \
        default dir --target /var/lib/libvirt/images

fi

if LC_ALL=C virsh -c qemu:///system pool-info default | grep -E '^State:[[:space:]]+running' >/dev/null; then
    echo "[OK] Storage pool is already active."
else
    virsh -c qemu:///system pool-start default
fi

virsh -c qemu:///system pool-autostart default

echo "Checking SSH key"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

SSH_KEY="$HOME/.ssh/cloudtask_ed25519"

if [ ! -f "$SSH_KEY" ]; then

    ssh-keygen -t ed25519 \
        -f "$SSH_KEY" \
        -C "cloudtask" \
        -N ""

fi

if [ ! -f "$SSH_KEY.pub" ]; then
    ssh-keygen -y -f "$SSH_KEY" > "$SSH_KEY.pub"
fi

chmod 600 "$SSH_KEY"

mkdir -p "$ROOT_DIR/.runtime"

"$ROOT_DIR/scripts/generate-secrets.sh"

echo "Installing Ansible dependencies"

ansible-galaxy collection install \
    -r "$ROOT_DIR/ansible/requirements.yml"

echo "=== BOOTSTRAP COMPLETE ==="