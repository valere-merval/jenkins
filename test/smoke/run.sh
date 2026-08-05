#!/usr/bin/env bash
#
# One-command local smoke test for the Jenkins shared library.
# Proves every vars/*.groovy facade loads its src/ class and delegates
# through methodMissing, without needing a live Jenkins.
#
# Usage:
#   ./test/smoke/run.sh
#
set -euo pipefail

# Resolve repo root from this script's location, so it works from anywhere.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${REPO_ROOT}"

if ! command -v groovy >/dev/null 2>&1; then
    echo "ERROR: 'groovy' CLI not found on PATH."
    echo "Install it, e.g.:"
    echo "  - SDKMAN:  sdk install groovy"
    echo "  - apt:     sudo apt-get install -y groovy"
    echo "  - brew:    brew install groovy"
    exit 127
fi

echo "Repo:   ${REPO_ROOT}"
echo "Groovy: $(groovy --version 2>&1 | head -1)"
echo "Running shared-library smoke test..."
echo

exec groovy -cp "src:test/smoke/stubs" test/smoke/LibraryLoadSpec.groovy
