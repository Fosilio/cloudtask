#!/usr/bin/env bash

set -euo pipefail

echo "=== CLOUDTASK NETWORK TEST ==="

echo "[TEST 1] Frontend -> Backend"

docker exec cloudtask-frontend \
    nc -z -w 5 backend.cloudtask.test 8000

echo "[PASS] Frontend can reach backend."

echo "[TEST 2] Backend -> Database"

docker exec cloudtask-backend python -c \
    "import socket; socket.create_connection(('db.cloudtask.test', 5432), 5).close()"

echo "[PASS] Backend can reach database."

echo "[TEST 3] Frontend -> Database"

# Confirm that DNS resolution works before testing isolation.
docker exec cloudtask-frontend nslookup db.cloudtask.test

if docker exec cloudtask-frontend \
    nc -z -w 5 db.cloudtask.test 5432; then

    echo "[FAIL] Frontend can reach database!"
    exit 1
else
    echo "[PASS] Frontend cannot reach database."
fi

echo "[TEST 4] Backend published ports"

if [ -n "$(docker port cloudtask-backend)" ]; then
    echo "[FAIL] Backend has published ports!"
    exit 1
fi

echo "[PASS] Backend has no published ports."

echo "[TEST 5] Database published ports"

if [ -n "$(docker port cloudtask-database)" ]; then
    echo "[FAIL] Database has published ports!"
    exit 1
fi

echo "[PASS] Database has no published ports."

echo "[TEST 6] Frontend published port"

docker port cloudtask-frontend 80/tcp | grep -q ':80$'

echo "[PASS] Frontend port 80 is published."

echo "=== ALL NETWORK TESTS PASSED ==="