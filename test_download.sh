#!/bin/bash
set -e

# Setup sandbox environment
SANDBOX=.sandbox-e2e
HOME_DIR="$PWD/$SANDBOX/home"
DOCKER_DIR="$PWD/$SANDBOX/docker"
BIN_DIR="$PWD/$SANDBOX/bin"

export HOME="$HOME_DIR"
export DOCKER_CONFIG="$DOCKER_DIR"
export PATH="$BIN_DIR:$PATH"

# Test hh download
echo "Testing hh download..."
hh download --prefix "$BIN_DIR"

# Check if ORAS was installed as binary
echo "Checking ORAS installation..."
file "$BIN_DIR/oras" | grep -q 'ELF 64-bit' && echo "✅ ORAS is a proper binary" || echo "❌ ORAS is not a proper binary"

# Check if hhfab was installed
echo "Checking hhfab installation..."
if [ -f "$BIN_DIR/hhfab" ]; then
    echo "✅ hhfab installed successfully"
    file "$BIN_DIR/hhfab"
else
    echo "❌ hhfab not found"
fi