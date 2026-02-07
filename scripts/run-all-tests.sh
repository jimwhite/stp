#!/usr/bin/env bash

set -e -u -o pipefail

# Get the STP root directory (parent of scripts/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STP_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=== Running All Tests ==="
echo "STP root: ${STP_ROOT}"

# Note: CaDiCaL tests are skipped - they require building the cadical binary
# which is not needed for STP (only the library is used). CryptoMiniSat tests
# exercise the CaDiCaL library indirectly.

# CryptoMiniSat tests
echo ""
echo "=== CryptoMiniSat Tests ==="
cd "${STP_ROOT}/deps/cryptominisat/build"
ctest --output-on-failure

# STP tests
echo ""
echo "=== STP Tests ==="
cd "${STP_ROOT}/build"
ctest --output-on-failure

echo ""
echo "=== All Tests Passed ==="
