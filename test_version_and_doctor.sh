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

echo "=== Testing hh --version ==="
hh --version

echo ""
echo "=== Testing hh version ==="
hh version

echo ""
echo "=== Testing hh doctor ==="
hh doctor