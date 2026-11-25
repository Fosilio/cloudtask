#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SECRETS_DIR="$ROOT_DIR/.secrets"

umask 077

mkdir -p "$SECRETS_DIR"
chmod 700 "$SECRETS_DIR"

if [ ! -s "$SECRETS_DIR/db_password" ]; then
    openssl rand -hex 32 > "$SECRETS_DIR/db_password"
    echo "Database password generated."
else
    echo "Database password already exists."
fi

if [ ! -s "$SECRETS_DIR/tsig_secret" ]; then
    openssl rand -base64 32 > "$SECRETS_DIR/tsig_secret"
    echo "TSIG secret generated."
else
    echo "TSIG secret already exists."
fi

chmod 600 "$SECRETS_DIR/db_password"
chmod 600 "$SECRETS_DIR/tsig_secret"

echo "Secrets are ready."