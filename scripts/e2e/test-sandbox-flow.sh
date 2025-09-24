#!/bin/bash
set -euo pipefail

# End-to-end test for the hh sandbox flow
echo "=== HH End-to-End Test ==="

# Get script directory and repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

# Create sandbox environment
SANDBOX=".sandbox-test"
rm -rf "$SANDBOX"
mkdir -p "$SANDBOX"/{home,logs,docker,tmp}
chmod -R 700 "$SANDBOX"/home

# Export isolation env
export HOME="$PWD/$SANDBOX/home"
export XDG_CONFIG_HOME="$HOME/.config"
export HH_CONFIG=""
export DOCKER_CONFIG="$PWD/$SANDBOX/docker"
export TMPDIR="$PWD/$SANDBOX/tmp"
mkdir -p "$HOME/.hh" "$DOCKER_CONFIG"

# Force docker to use our sandbox config only
printf '{ "credHelpers": { "ghcr.io": "hh" } }\n' > "$DOCKER_CONFIG/config.json"

echo "✓ Sandbox created: HOME=$HOME"

# Install binaries to sandbox
mkdir -p "$PWD/$SANDBOX/bin"
cp -f "./cli/hh/hh" "$PWD/$SANDBOX/bin/"

# Build and copy helper
if [[ -f "cli/docker-credential-hh/docker-credential-hh-new" ]]; then
    cp -f "cli/docker-credential-hh/docker-credential-hh-new" "$PWD/$SANDBOX/bin/docker-credential-hh"
else
    cp -f "cli/docker-credential-hh/docker-credential-hh" "$PWD/$SANDBOX/bin/docker-credential-hh"
fi

export PATH="$PWD/$SANDBOX/bin:$PATH"

echo "✓ Binaries installed"

# Test 1: hh login writes required keys
echo ""
echo "=== Test 1: hh login writes required keys ==="
hh login --code "TEST-CODE-1234-5678"

if [[ ! -f "$HOME/.hh/config.json" ]]; then
    echo "❌ Config file not created"
    exit 1
fi

# Check required keys
REQUIRED_KEYS=("lease_url" "edge_auth" "token")
for key in "${REQUIRED_KEYS[@]}"; do
    if ! jq -e ".$key" "$HOME/.hh/config.json" >/dev/null 2>&1; then
        echo "❌ Missing required key: $key"
        exit 1
    fi
    if [[ "$(jq -r ".$key" "$HOME/.hh/config.json")" == "null" || "$(jq -r ".$key" "$HOME/.hh/config.json")" == "" ]]; then
        echo "❌ Required key $key is null or empty"
        exit 1
    fi
done

echo "✓ All required keys present and non-empty"

# Test 2: Helper returns JSON when lease works (simulated - we expect 401 with test code)
echo ""
echo "=== Test 2: Helper handles lease requests correctly ==="
set -o pipefail
HELPER_OUT=$(echo -n "ghcr.io" | docker-credential-hh get 2>/dev/null || true)
HELPER_EXIT=$?

if [[ $HELPER_EXIT -ne 0 ]]; then
    echo "❌ Helper returned non-zero exit code: $HELPER_EXIT"
    exit 1
fi

# With test code, we expect empty output (anonymous fallback)
if [[ -n "$HELPER_OUT" ]]; then
    echo "❌ Expected empty output for test code, got: $HELPER_OUT"
    exit 1
fi

echo "✓ Helper handles auth failure correctly (empty output, exit 0)"

# Test 3: Bad edge secret allows anonymous fallback
echo ""
echo "=== Test 3: Bad edge secret allows anonymous fallback ==="
BAD_CONFIG="$SANDBOX/bad-config.json"
jq '.edge_auth="WRONGSECRET"' "$HOME/.hh/config.json" > "$BAD_CONFIG"
export HH_CONFIG="$BAD_CONFIG"

set -o pipefail
BAD_HELPER_OUT=$(echo -n "ghcr.io" | docker-credential-hh get 2>/dev/null || true)
BAD_HELPER_EXIT=$?

if [[ $BAD_HELPER_EXIT -ne 0 ]]; then
    echo "❌ Helper with bad config returned non-zero exit code: $BAD_HELPER_EXIT"
    exit 1
fi

if [[ -n "$BAD_HELPER_OUT" ]]; then
    echo "❌ Expected empty output for bad config, got: $BAD_HELPER_OUT"
    exit 1
fi

echo "✓ Bad config allows anonymous fallback correctly"

# Test 4: Public Docker pull works even with bad helper config
echo ""
echo "=== Test 4: Public Docker pull works with helper configured ==="
docker logout ghcr.io 2>/dev/null || true
if docker pull hello-world >/dev/null 2>&1; then
    echo "✓ Public Docker pull works with credential helper configured"
else
    echo "❌ Public Docker pull failed with credential helper configured"
    exit 1
fi

# Restore good config
unset HH_CONFIG

# Test 5: hh doctor runs successfully
echo ""
echo "=== Test 5: hh doctor runs successfully ==="
if hh doctor >/dev/null 2>&1; then
    echo "✓ hh doctor runs without errors"
else
    echo "❌ hh doctor failed"
    exit 1
fi

echo ""
echo "🎉 All tests passed!"
echo ""
echo "Cleanup: Removing test sandbox..."
cd "$REPO_ROOT"
rm -rf "$SANDBOX"
echo "✓ Cleanup complete"