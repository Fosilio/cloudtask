#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR/ansible"

echo "Waiting for CloudTask server..."

ansible cloudtask -m wait_for_connection \
    -a "timeout=300 sleep=5 connect_timeout=10"

echo "Server is ready."