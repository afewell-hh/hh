# hh
installer

## Quickstart

1) Install hh CLI

	curl -fsSL https://github.com/afewell-hh/hh/releases/latest/download/install-hh.sh | bash

2) Login with pairing code

	hh login --code "YOUR_PAIRING_CODE"

	This writes `~/.hh/config.json` with your `portal_base` and `download_token`.

3) Install helper and optional tools

	hh download

	By default this will install the Docker credential helper and optionally `hhfab` and `oras` to `/usr/local/bin`.

4) Next steps

	mkdir -p ~/hhfab-dir && cd ~/hhfab-dir
	hhfab init --dev
	hhfab vlab gen
	hhfab build

## Docker permissions

### Preferred: Sudoless Docker (recommended)

If Docker requires elevated privileges (permission denied on socket), add your user to the docker group:

	sudo usermod -aG docker $USER && newgrp docker

Then run `hh download` normally.

### Alternative: System mode for sudo-required environments

For environments where sudo is required for Docker (CI, hardened servers), use system mode:

	hh login --system --code "YOUR_PAIRING_CODE"
	hh download --system

System mode:
- Writes config to `/etc/hh/config.json` (accessible to root)
- Installs credential helper to `/usr/local/bin`
- Configures Docker for both user and root (`/root/.docker/config.json`)
- Supports `sudo docker pull` commands

## Configuration

The credential helper searches for configuration in this order:

1. `$HH_CONFIG` (if set)
2. `/etc/hh/config.json` (system)
3. `$XDG_CONFIG_HOME/hh/config.json` (if set)
4. `$HOME/.hh/config.json` (user)

## Examples

### Install only the Docker helper
	hh download --no-hhfab --no-oras

### Test with a specific image
	hh download --sanity ghcr.io/ORG/IMAGE:TAG

### System mode for CI/hardened environments
	hh login --system --code "CODE"
	hh download --system
