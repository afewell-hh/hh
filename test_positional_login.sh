#!/bin/bash
set -e

# Setup fresh sandbox environment
SANDBOX=.sandbox-positional
rm -rf "$SANDBOX"
mkdir -p "$SANDBOX"/{home,docker,bin}
HOME_DIR="$PWD/$SANDBOX/home"
DOCKER_DIR="$PWD/$SANDBOX/docker"
BIN_DIR="$PWD/$SANDBOX/bin"

export HOME="$HOME_DIR"
export DOCKER_CONFIG="$DOCKER_DIR"

# Copy binaries
cp ./cli/hh/hh "$BIN_DIR/hh"
chmod +x "$BIN_DIR/hh"

echo "=== Testing positional pairing code argument ==="
"$BIN_DIR/hh" login TEST-CODE-1234

echo ""
echo "=== Verifying config was written ==="
jq -r '.lease_url, .edge_auth, .token' "$HOME/.hh/config.json"