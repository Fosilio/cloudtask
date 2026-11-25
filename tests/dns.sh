#!/usr/bin/env bash

set -euo pipefail

DNS_SERVER="${1:?DNS server IP required}"

echo "=== CLOUDTASK DNS TEST ==="

echo "[TEST 1] Authoritative DNS zone"

dig @"$DNS_SERVER" cloudtask.test SOA \
    +norecurse +noall +comments +answer |
    grep -E 'flags:.* aa'

echo "[PASS] Authoritative answer received."

check_record() {
    local name="$1"
    local expected="$2"
    local actual

    actual=$(dig @"$DNS_SERVER" "$name" A +short)

    if [ "$actual" != "$expected" ]; then
        echo "[FAIL] $name returned $actual"
        echo "Expected: $expected"
        exit 1
    fi

    echo "[PASS] $name -> $actual"
}

check_record frontend.cloudtask.test "$DNS_SERVER"
check_record backend.cloudtask.test 172.20.20.20
check_record db.cloudtask.test 172.20.30.30

echo "[TEST 5] Unauthorized DNS update"

if printf 'server %s\nzone cloudtask.test.\nupdate add unauthorized-test.cloudtask.test. 300 A 192.0.2.123\nsend\n' \
    "$DNS_SERVER" | nsupdate; then

    echo "[FAIL] Unauthorized update was accepted!"
    exit 1
else
    echo "[INFO] Unsigned update was rejected."
fi

if [ -n "$(dig @"$DNS_SERVER" unauthorized-test.cloudtask.test A +short)" ]; then
    echo "[FAIL] Unauthorized record exists!"
    exit 1
fi

echo "[PASS] Unauthorized DNS record does not exist."

echo "=== ALL DNS TESTS PASSED ==="