# hh User Guide

This guide helps end users get started with `hh`, the Hedgehog download & setup utility.

## What is hh?

`hh` is a bootstrapping tool that:
- Configures Docker authentication for GitHub Container Registry (GHCR)
- Installs necessary tools like `hhfab` and `oras`
- Uses your pairing code to securely access Hedgehog software

## Quick Start

### 1. Install hh

```bash
curl -fsSL https://github.com/afewell-hh/hh/releases/download/v0.1.12/install-hh.sh | bash
```

### 2. Verify installation

```bash
hh --version
```

### 3. Login with your pairing code

```bash
hh login --code "YOUR_PAIRING_CODE"
```

Replace `YOUR_PAIRING_CODE` with the token from your email.

### 4. Download tools and configure authentication

```bash
hh download
```

### 5. Start using hhfab

```bash
mkdir -p ~/hhfab-dir && cd ~/hhfab-dir
hhfab init --dev
hhfab vlab gen
hhfab build
```

## Diagnostics with hh doctor

If something isn't working, run:

```bash
hh doctor
```

This will check:
- Docker installation and permissions
- Credential helper installation
- Configuration files
- Helper functionality
- ORAS installation
- Public registry access

## Common Issues

### 1. Docker Permission Denied

**Problem:** `docker: permission denied while trying to connect to Docker daemon`

**Solution:** Add yourself to the docker group:
```bash
sudo usermod -aG docker $USER && newgrp docker
```

### 2. Helper Returns No Credentials

**Problem:** Docker pulls fail with authentication errors

**Solution:**
1. Check if helper is working: `echo -n ghcr.io | docker-credential-hh get`
2. If empty, re-login: `hh login --code "YOUR_PAIRING_CODE"`
3. Verify config exists: `ls -la ~/.hh/config.json`

### 3. Pairing Code Issues

**Problem:** Login fails or 401/403 errors

**Solutions:**
- Wait 2-3 minutes and try again (token may be propagating)
- Check your email for a new pairing code
- Contact support if the code appears invalid

### 4. ORAS Not Working

**Problem:** hhfab fails to download or ORAS appears to be a script

**Solution:**
```bash
sudo rm -f /usr/local/bin/oras
hh download
```

This will reinstall ORAS as a proper binary.

## System Mode (Advanced)

For environments that require `sudo docker` (CI systems, hardened servers):

```bash
# Login in system mode
hh login --system --code "YOUR_PAIRING_CODE"

# Download in system mode
hh download --system
```

System mode:
- Stores config in `/etc/hh/config.json`
- Configures both user and root Docker configs
- Supports `sudo docker pull` commands

## Getting Help

1. **Run diagnostics:** `hh doctor` shows system status
2. **Check logs:** Look at command output for specific errors
3. **GitHub Issues:** Report problems at the repository with:
   - Output of `hh doctor`
   - Your specific error messages
   - Steps to reproduce the issue

## Files Created by hh

- `~/.hh/config.json` - Your authentication configuration
- `~/.docker/config.json` - Docker credential helper configuration
- `/usr/local/bin/docker-credential-hh` - The credential helper binary
- `/usr/local/bin/oras` - ORAS tool for artifact downloads
- `/usr/local/bin/hhfab` - Hedgehog Fabricator tool

## Security Notes

- Your pairing code is stored locally in `~/.hh/config.json`
- The credential helper exchanges your code for temporary credentials
- No personal information is transmitted or stored remotely
- Credentials are cached for short periods to improve performance