# hh
installer

## Quickstart

1) Install hh CLI

	curl -fsSL https://github.com/afewell-hh/hh/releases/latest/download/install-hh.sh | bash

2) Login with pairing code

	hh login --code "YOUR_PAIRING_CODE"

	This writes `~/.hh/config.json` with your `lease_url` and `token`.

	To verify installation: `hh --version` or `hh version`

3) Install helper and optional tools

	hh download

	By default this will:
	- Auto-download the Docker credential helper from GitHub releases if not present locally
	- Install architecture-specific binaries (linux-amd64, linux-arm64) with shell script fallback
	- Install `hhfab` and `oras` tools to `/usr/local/bin`
	- Configure Docker credential helpers for `ghcr.io`

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

## Auto-Install Behavior

`hh download` automatically fetches the credential helper from GitHub releases if not found locally:

1. **Architecture Detection**: Detects system architecture (x86_64 → linux-amd64, aarch64 → linux-arm64)
2. **Binary Download**: Attempts to download arch-specific binary: `docker-credential-hh-linux-amd64` or `docker-credential-hh-linux-arm64`
3. **Checksum Verification**: Verifies download integrity using `.sha256` files when available
4. **Shell Fallback**: Falls back to universal `docker-credential-hh.sh` if arch-specific binary unavailable
5. **Installation**: Installs to `/usr/local/bin` (requires sudo) or `~/.local/bin` (with PATH hint) as fallback

No extra flags required - just run `hh download` and it handles everything automatically.

## Examples

### Install only the Docker helper
	hh download --no-hhfab --no-oras

### Test with a specific image
	hh download --sanity ghcr.io/ORG/IMAGE:TAG

### System mode for CI/hardened environments
	hh login --system --code "CODE"
	hh download --system

### Manual helper download (override auto-install)
	hh download --helper-url https://github.com/afewell-hh/hh/releases/latest/download/docker-credential-hh-linux-amd64 --sha256-helper <checksum>

### Version information
	hh --version
	hh version

## Security

### How secrets are stored

All sensitive credentials are stored securely in AWS Secrets Manager:
- HubSpot application secrets are stored at `/hh/prod/hubspot/*`
- GitHub Container Registry (GHCR) credentials are stored at `/hh/prod/ghcr/*`
- Lambda functions retrieve secrets at runtime using IAM roles
- No plaintext secrets are stored in Lambda environment variables
- Supports zero-downtime secret rotation without redeployment
