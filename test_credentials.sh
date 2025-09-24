#!/bin/bash
set -e

# Setup sandbox environment
SANDBOX=.sandbox-e2e
HOME_DIR="$PWD/$SANDBOX/home"
DOCKER_DIR="$PWD/$SANDBOX/docker"
BIN_DIR="$PWD/$SANDBOX/bin"

export HOME="$HOME_DIR"
export DOCKER_CONFIG="$DOCKER_DIR"

# Test credential helper
echo "Testing credential helper..."
echo -n ghcr.io | "$BIN_DIR/docker-credential-hh" get | jq .