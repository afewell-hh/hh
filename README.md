# hh — Hedgehog download & setup utility

Installs the Docker credential helper and (optionally) hhfab, enabling authenticated pulls from GHCR for Hedgehog builds.

## Table of Contents

- [What is this?](#what-is-this)
- [Quickstart](#quickstart)
- [Prerequisites](#prerequisites)
- [Relationship to hhfab](#relationship-to-hhfab)
- [Modes](#modes)
- [hh --help and hh --version](#hh---help-and-hh---version)
- [Diagnostics](#diagnostics)
- [Troubleshooting](#troubleshooting)
- [Security model](#security-model)
- [Uninstall](#uninstall)
- [Support](#support)
- [Changelog & License](#changelog--license)

## What is this?

• Installs a Docker credential helper for ghcr.io
• Handles authenticated pulls using your pairing code (token)
• Optionally installs hhfab and oras
• Works on Ubuntu 22.04/24.04; both "user" and "system (sudo)" modes

## Quickstart

### Pinned release (current):

```bash
curl -fsSL https://github.com/afewell-hh/hh/releases/download/v0.1.12/install-hh.sh | bash
hh --version
hh login --code "<YOUR_PAIRING_CODE>"
hh download
```

### Optional: latest track

```bash
HH_VERSION=latest curl -fsSL https://github.com/afewell-hh/hh/releases/latest/download/install-hh.sh | bash
```

## Prerequisites

Docker installed; if Docker requires sudo, show:

```bash
sudo usermod -aG docker $USER && newgrp docker
```

`curl` and `jq` recommended (for diagnostics).

## Relationship to hhfab

`hh` bootstraps auth and can install hhfab; you'll typically:

```bash
mkdir -p ~/hhfab-dir && cd ~/hhfab-dir
hhfab init --dev
hhfab vlab gen
hhfab build
```

## Modes

**User mode (recommended):** installs helper under $HOME / user Docker config.

**System mode (hardened/CI):**

```bash
hh login --system --code "<YOUR_PAIRING_CODE>"
hh download --system
# Then use sudo docker ... if your environment requires it
```

## hh --help and hh --version

### Sample hh --version output (v0.1.12):

```
hh v0.1.12
commit: fef0db1
built: 2025-09-24T15:23:02Z
```

### Sample hh --help output:

```
usage: hh [-h] [--version] {version,doctor,login,download} ...

positional arguments:
  {version,doctor,login,download}
    version             Show version information
    doctor              Run diagnostic checks
    login
    download            Install helper and optional binaries; see examples below

options:
  -h, --help            show this help message and exit
  --version             Show version information
```

**Note:** Use `hh doctor` for comprehensive system diagnostics.

## Diagnostics

### Sample hh doctor output:

```
hh v0.1.12
commit: fef0db1

🔍 Checking Docker...
✅ Docker is accessible

🔍 Checking credential helper...
✅ Helper found at: /usr/local/bin/docker-credential-hh

🔍 Checking configuration...
✅ Config found: /home/user/.hh/config.json
✅ All required config keys present

🔍 Testing credential helper...
✅ Helper returned credentials

🔍 Checking ORAS...
✅ ORAS found at: /usr/local/bin/oras
✅ ORAS is a proper binary (not a script)

🔍 Testing public registry access...
✅ Public Docker pull works
```

## Troubleshooting

### Helper returns no output / anonymous fallback
Ensure `~/.hh/config.json` has `lease_url` and `token`. Run `hh login --code "..."` again.

```bash
# Test helper directly
echo -n ghcr.io | docker-credential-hh get
```

If this prints nothing and returns exit code 0, the helper is in anonymous fallback mode.

### oras is a shell script / corrupted
`hh download` now installs the official ELF binary; if broken, run:

```bash
sudo rm -f /usr/local/bin/oras
hh download
```

### Docker needs sudo
Add user to docker group or run system mode:

```bash
# Option A: Fix permissions (recommended)
sudo usermod -aG docker $USER && newgrp docker

# Option B: Use system mode
hh login --system --code "<YOUR_PAIRING_CODE>"
hh download --system
```

### hhfab init fails with GHCR 401/403
Pairing code invalid/disabled; contact support.

### HubSpot email didn't arrive / token empty
Wait 2–3 min or request re-send.

## Security model

• Pairing code is stored locally; helper exchanges it for short-use credentials via /lease
• Secrets are managed in AWS Secrets Manager (no plaintext in Lambda envs)
• No PII stored by hh; logs mask emails

## Uninstall

```bash
# remove helper & config
rm -f ~/.local/bin/docker-credential-hh ~/.hh/config.json
# optionally revert ~/.docker/config.json credHelpers entry for ghcr.io
```

## Support

For issues, please open a GitHub issue with the following information:

- Output of `hh doctor`
- Output of `docker-credential-hh get` (if applicable)
- Any error messages or logs

## Changelog & License

See [CHANGELOG.md](CHANGELOG.md) for version history.