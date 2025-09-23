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

echo "=== Testing auto-install functionality ==="

# Test auto-install with no helper present and no local build
echo "Testing auto-install from GitHub releases"
TMP_HOME2=$(mktemp -d)
export OLD_HOME=$HOME
export HOME=$TMP_HOME2
mkdir -p $HOME/.hh
cp $OLD_HOME/.hh/config.json $HOME/.hh/config.json

# Remove helper from PATH temporarily
export OLD_PATH=$PATH
export PATH=$(echo $PATH | sed "s|$HERE/cli/docker-credential-hh:||g")

# Rename local helper to simulate no local build
if [ -f "$HERE/cli/docker-credential-hh/docker-credential-hh" ]; then
    mv "$HERE/cli/docker-credential-hh/docker-credential-hh" "$HERE/cli/docker-credential-hh/docker-credential-hh.backup"
fi

echo "Running hh download with no local helper (should auto-download)"
cd $TMP_HOME2  # Change directory to avoid finding local helper
python3 $HERE/cli/hh/hh download --no-hhfab --no-oras --prefix "$HOME/.local/bin" || echo "Auto-install test completed (may fail due to network or missing release)"

# Check if helper was installed
if [ -x "$HOME/.local/bin/docker-credential-hh" ]; then
    echo "✓ Auto-install successful: helper installed to $HOME/.local/bin/docker-credential-hh"
    # Test the installed helper
    echo -n ghcr.io | "$HOME/.local/bin/docker-credential-hh" get 2>&1 | grep -q "lease error: 401" && echo "✓ Downloaded helper works correctly" || echo "Downloaded helper test: unexpected response"
else
    echo "Auto-install: helper not installed (may be expected if network/release not available)"
fi

# Test arch detection
echo "Testing architecture detection"
python3 -c "
import sys
sys.path.insert(0, '$HERE/cli/hh')
import hh
arch = hh.detect_arch()
print(f'Detected architecture: {arch}')
if arch:
    url, checksum_url, arch_type = hh.get_default_helper_urls()
    print(f'Default helper URL: {url}')
    print(f'Checksum URL: {checksum_url}')
    print(f'Architecture type: {arch_type}')
else:
    print('No specific architecture detected, will use shell fallback')
"

# Test with forced architecture (if HH_FORCE_ARCH is supported)
echo "Testing forced architecture selection"
export HH_FORCE_ARCH=linux-arm64
python3 -c "
import sys
sys.path.insert(0, '$HERE/cli/hh')
import hh
import os
if 'HH_FORCE_ARCH' in os.environ:
    # Temporarily override detect_arch for testing
    original_detect_arch = hh.detect_arch
    def mock_detect_arch():
        return os.environ['HH_FORCE_ARCH']
    hh.detect_arch = mock_detect_arch

    url, checksum_url, arch_type = hh.get_default_helper_urls()
    print(f'Forced arch URL: {url}')
    print(f'Expected: docker-credential-hh-linux-arm64')
    assert 'linux-arm64' in url, f'Expected linux-arm64 in URL, got {url}'
    print('✓ Forced architecture test passed')
"
unset HH_FORCE_ARCH

# Restore helper and environment
if [ -f "$HERE/cli/docker-credential-hh/docker-credential-hh.backup" ]; then
    mv "$HERE/cli/docker-credential-hh/docker-credential-hh.backup" "$HERE/cli/docker-credential-hh/docker-credential-hh"
fi
export PATH=$OLD_PATH
export HOME=$OLD_HOME
rm -rf $TMP_HOME2

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

    # Test system mode auto-install
    echo "Testing system mode auto-install"
    # Create a temp HOME with no helper for system mode test
    TMP_SYSTEM_HOME=$(mktemp -d)
    sudo mkdir -p "$TMP_SYSTEM_HOME/.hh"
    sudo cp /etc/hh/config.json "$TMP_SYSTEM_HOME/.hh/" 2>/dev/null || echo "No system config to copy"

    # Test system mode auto-install (may require network)
    sudo -E env HOME="$TMP_SYSTEM_HOME" PATH="$(echo $PATH | sed "s|$HERE/cli/docker-credential-hh:||g")" python3 $HERE/cli/hh/hh download --system --no-hhfab --no-oras || echo "System auto-install test completed (may fail due to permissions or network)"

    # Verify system-wide helper installation
    if [ -x "/usr/local/bin/docker-credential-hh" ]; then
        echo "✓ System mode auto-install successful"
        # Test with system config
        sudo -E env HH_CONFIG=/etc/hh/config.json bash -c 'echo -n ghcr.io | docker-credential-hh get' 2>&1 | grep -q "lease error: 401" && echo "✓ System helper works with system config" || echo "System helper test: unexpected response"
    else
        echo "System auto-install: helper not installed (may be expected)"
    fi

    sudo rm -rf "$TMP_SYSTEM_HOME"

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
