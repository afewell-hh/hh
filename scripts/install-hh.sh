#!/usr/bin/env bash
set -euo pipefail

REPO="afewell-hh/hh"
PREFIX="${HH_PREFIX:-/usr/local/bin}"
# Use specific v0.1.12 release for stable rollout
HH_VERSION="${HH_VERSION:-v0.1.12}"
HH_URL="https://github.com/${REPO}/releases/download/${HH_VERSION}/hh"

need() { command -v "$1" >/dev/null 2>&1 || { echo "error: $1 is required"; exit 1; }; }
need curl

# Optional: python3 is required by the current hh CLI (Python). Warn if missing.
if ! command -v python3 >/dev/null 2>&1; then
  echo "warning: python3 not found; the hh CLI requires python3 in PATH."
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
dst="${PREFIX}/hh"

echo "Downloading hh ${HH_VERSION} from: $HH_URL"
curl -fsSL "$HH_URL" -o "${tmp}/hh"
chmod +x "${tmp}/hh"

# Install to PREFIX (sudo if needed)
if install -d -m 0755 "$PREFIX" 2>/dev/null && install -m 0755 "${tmp}/hh" "$dst" 2>/dev/null; then
  :
else
  echo "Elevating to install into ${PREFIX}…"
  sudo install -d -m 0755 "$PREFIX"
  sudo install -m 0755 "${tmp}/hh" "$dst"
fi

echo "✅ Successfully installed hh to ${dst}"
"$dst" --help >/dev/null 2>&1 || echo "note: run 'hh --help' to verify, ensure python3 is available"

echo ""
echo "🚀 Next steps:"
echo "   1. Get your pairing code from the download email"
echo "   2. Run: hh login --code \"<YOUR_PAIRING_CODE>\""
echo "   3. Run: hh download"
echo ""
echo "Need help? Check the docs or reply to the download email."
