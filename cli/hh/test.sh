#!/usr/bin/env bash
set -euo pipefail

HERE=$(pwd)
TMP=$(mktemp -d)

export HOME=$TMP
mkdir -p $HOME/.hh
cat > $HOME/.hh/config.json <<'JSON'
{
  "portal_base": "https://pc4x1xgehc.execute-api.us-west-2.amazonaws.com",
  "download_token": "TEST-1234"
}
JSON

export PATH="$HERE/cli/docker-credential-hh:$PATH"

echo "Running hh download (no hhfab/no-oras/no-helper)"
python3 $HERE/cli/hh/hh download --no-hhfab --no-oras --no-helper || true

echo "Running hh download (install helper + merge docker config)"
python3 $HERE/cli/hh/hh download --no-hhfab --no-oras || true

# ensure helper present in PATH for this test
echo -n ghcr.io | docker-credential-hh get | jq -e '.Username and .Secret' >/dev/null && echo OK || (echo FAIL && exit 1)

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

echo Success
