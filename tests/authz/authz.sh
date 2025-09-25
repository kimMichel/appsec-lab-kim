#!/usr/bin/env bash
set -euo pipefail

CFG="tests/authz/config.json"
BASE=$(jq -r '.baseURL' "$CFG")

tok()   { jq -r ".users.$1.token" "$CFG"; }
res()   { jq -r ".resources.$1" "$CFG"; }

T_USERA=$(tok userA)
T_USERB=$(tok userB)
T_ADMIN=$(tok admin)

INV_T1=$(res invoiceFromTenant1)  # belongs to tenant T1
INV_T2=$(res invoiceFromTenant2)  # belongs to tenant T2

# Helper: curl that returns only HTTP status
req() {
  local METHOD=$1; shift
  local URL=$1; shift
  local TOKEN=$1; shift
  curl -s -o /dev/null -w "%{http_code}" -X "$METHOD" \
    -H "Authorization: $TOKEN" -H "Content-Type: application/json" \
    "$URL" "$@"
}

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1"; exit 1; }

echo "=== Check #1: Cross-tenant READ must be denied (IDOR/BOLA) ==="
# userA tries to read invoice from tenant T2 → expect 403/404 (NOT 200)
S1=$(req GET "$BASE/invoices/$INV_T2" "$T_USERA")
if [[ "$S1" == "403" || "$S1" == "404" ]]; then
  pass "userA cannot read T2 invoice ($S1)"
else
  fail "userA READ T2 invoice returned $S1 (expected 403/404)"
fi

echo "=== Check #2: Role-based UPDATE must be enforced ==="
# userA (non-admin) tries to PATCH invoice status → expect 403
S2=$(req PATCH "$BASE/invoices/$INV_T1" "$T_USERA" --data '{"status":"PAID"}')
if [[ "$S2" == "403" || "$S1" == "404" ]]; then
  pass "userA cannot PATCH invoice ($S2)"
else
  fail "userA PATCH returned $S2 (expected 403)"
fi

# sanity: admin can PATCH → expect 200/204
S3=$(req PATCH "$BASE/invoices/$INV_T1" "$T_ADMIN" --data '{"status":"PAID"}')
if [[ "$S3" == "200" || "$S3" == "204" ]]; then
  pass "admin can PATCH invoice ($S3)"
else
  fail "admin PATCH returned $S3 (expected 200/204)"
fi

echo "All authz checks passed."
