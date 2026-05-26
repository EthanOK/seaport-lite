#!/usr/bin/env bash
# Print Bulk order typehashes (heights 1–24) for pasting into constants files.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

echo "=== SeaportLite (standard OrderComponents) ==="
echo "  forge test --match-contract SeaportLiteTest --match-test test_getBulkOrderTypeHashs -vv"
echo ""
echo "=== CustomBulkSeaport (custom OrderComponents members) ==="
echo "  forge test --match-contract GenerateCustomBulkOrderTypeHash -vv"
echo "  → paste into src/variants/CustomConsiderationConstants.sol"
echo ""

forge test --match-contract GenerateCustomBulkOrderTypeHash -vv 2>/dev/null || true
