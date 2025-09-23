#!/usr/bin/env bash
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export PATH="$HERE:$PATH"
echo -n ghcr.io | docker-credential-hh get | jq -e '.Username and .Secret' >/dev/null
echo "OK"
echo -n https://ghcr.io | docker-credential-hh get | jq -e '.Username and .Secret' >/dev/null
echo "OK"
