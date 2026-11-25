#!/usr/bin/env bash

set -euo pipefail

APP_URL="http://127.0.0.1"
TASK_NAME="Persistence test $(date +%s)"

cd /opt/cloudtask

echo "=== CLOUDTASK PERSISTENCE TEST ==="

echo "[TEST 1] Create test task"

TASK=$(curl -fsS \
    -X POST "$APP_URL/api/tasks" \
    -H "Content-Type: application/json" \
    -d "{\"title\":\"$TASK_NAME\"}")

TASK_ID=$(echo "$TASK" | python3 -c \
    'import json,sys; print(json.load(sys.stdin)["id"])')

echo "[PASS] Created task ID: $TASK_ID"

OLD_CONTAINER=$(docker inspect \
    --format '{{.Id}}' cloudtask-database)

echo "[TEST 2] Recreate PostgreSQL container"

docker compose up -d \
    --force-recreate \
    --no-deps \
    --wait \
    --wait-timeout 120 \
    database

NEW_CONTAINER=$(docker inspect \
    --format '{{.Id}}' cloudtask-database)

if [ "$OLD_CONTAINER" = "$NEW_CONTAINER" ]; then
    echo "[FAIL] Container was not recreated!"
    exit 1
fi

echo "[PASS] Database container recreated."

echo "[TEST 3] Wait for application recovery"

curl -fsS \
    --retry 15 \
    --retry-all-errors \
    --retry-delay 2 \
    "$APP_URL/api/health"

echo

echo "[TEST 4] Verify persisted task"

curl -fsS "$APP_URL/api/tasks" |
    python3 -c "
import json, sys

tasks = json.load(sys.stdin)
task_id = int(sys.argv[1])

assert any(t['id'] == task_id for t in tasks), \
    'Persisted task not found!'
" "$TASK_ID"

echo "[PASS] Task survived database recreation."

echo "[TEST 5] Remove test task"

curl -fsS -X DELETE "$APP_URL/api/tasks/$TASK_ID"

echo
echo "=== PERSISTENCE TEST PASSED ==="