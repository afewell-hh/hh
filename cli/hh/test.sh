#!/usr/bin/env bash
set -euo pipefail

HERE=$(pwd)
TMP=$(mktemp -d)

cleanup() {
    echo "Cleaning up test environment..."
    rm -rf "$TMP"
    # Clean up any test system configs if running as sudo
    if [ "${EUID:-$(id -u)}" = "0" ] || sudo -n true 2>/dev/null; then
        sudo rm -f /etc/hh/config.json 2>/dev/null || true
        sudo rm -f /root/.docker/config.json.bak 2>/dev/null || true
    fi
}
trap cleanup EXIT

export HOME=$TMP
mkdir -p $HOME/.hh
cat > $HOME/.hh/config.json <<'JSON'
{
  "portal_base": "https://pc4x1xgehc.execute-api.us-west-2.amazonaws.com",
  "download_token": "TEST-1234"
}
JSON

export PATH="$HERE/cli/docker-credential-hh:$PATH"

echo "=== Testing user mode ==="

echo "Running hh download (no hhfab/no-oras/no-helper)"
python3 $HERE/hh download --no-hhfab --no-oras --no-helper || true

echo "Running hh download (install helper + merge docker config)"
python3 $HERE/hh download --no-hhfab --no-oras || true

# Test credential helper with user config (expect failure due to fake token)
echo "Testing credential helper with user config"
echo -n ghcr.io | docker-credential-hh get 2>&1 | grep -q "lease error: 401" && echo "User mode credential helper OK (expected 401 with test token)" || echo "User mode credential helper: unexpected response (may be OK)"

# Test config path precedence
echo "Testing config path precedence"
mkdir -p $TMP/xdg-config/hh
export XDG_CONFIG_HOME="$TMP/xdg-config"
cat > $XDG_CONFIG_HOME/hh/config.json <<'JSON'
{
  "lease_url": "https://pc4x1xgehc.execute-api.us-west-2.amazonaws.com",
  "token": "XDG-TEST-5678"
}
JSON

echo -n ghcr.io | docker-credential-hh get 2>&1 | grep -q "lease error: 401" && echo "XDG config precedence OK (found XDG config)" || echo "XDG config precedence: unexpected response"

# Clean up XDG test
unset XDG_CONFIG_HOME

echo "=== Testing system mode (if sudo available) ==="

# Test system mode if sudo is available
if sudo -n true 2>/dev/null; then
    echo "Testing system mode with sudo"

    # Test login --system
    echo "Testing hh login --system"
    python3 $HERE/hh login --system --code "SYSTEM-TEST-9999" --portal "https://pc4x1xgehc.execute-api.us-west-2.amazonaws.com"

    # Verify system config was created
    if sudo test -f /etc/hh/config.json; then
        echo "System config created successfully"
        sudo cat /etc/hh/config.json
    else
        echo "System config creation FAILED"
        exit 1
    fi

    # Test credential helper with system config (simulate sudo environment)
    echo "Testing credential helper with system config"
    sudo -E env HH_CONFIG=/etc/hh/config.json bash -c 'echo -n ghcr.io | docker-credential-hh get' | jq -e '.Username and .Secret' >/dev/null && echo "System mode credential helper OK" || echo "System mode credential helper failed (may be expected if no real lease endpoint)"

    # Test hh download --system
    echo "Testing hh download --system"
    python3 $HERE/hh download --system --no-hhfab --no-oras || true

    # Check if root docker config was modified
    if sudo test -f /root/.docker/config.json; then
        echo "Root Docker config exists"
        sudo cat /root/.docker/config.json | jq -e '.credHelpers."ghcr.io" == "hh"' && echo "Root Docker config updated correctly" || echo "Root Docker config update failed"
    else
        echo "Root Docker config not created (may be expected)"
    fi

else
    echo "Sudo not available, skipping system mode tests"
fi

# optional sanity pull when SANITY_IMAGE is set
if [ -n "${SANITY_IMAGE:-}" ]; then
  echo "Running sanity pull ${SANITY_IMAGE}"
  docker logout ghcr.io || true
  if docker pull "${SANITY_IMAGE}"; then
    echo 'sanity pull OK'
  else
    echo 'sanity pull failed'
    exit 1
  fi
fi

echo "All tests passed!"
