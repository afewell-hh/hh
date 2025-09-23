# hh
installer

## Quickstart

1) Login (pairing code)

	hh login

	This prompts for the pairing code and writes `~/.hh/config.json` with your `portal_base` and `download_token`.

2) Install helper and optional tools

	curl -fsSL https://github.com/afewell-hh/hh/releases/latest/download/install-hh.sh | bash

	(alt) curl -fsSL https://raw.githubusercontent.com/afewell-hh/hh/main/scripts/install-hh.sh | bash

	By default this will install the Docker credential helper and optionally `hhfab` and `oras` to `/usr/local/bin`.

	If Docker reports permission denied on the socket, run:

		sudo usermod -aG docker $USER && newgrp docker

3) Sanity pull example (optional)

	hh download --sanity ghcr.io/ORG/IMAGE:TAG

4) Next steps

	mkdir -p ~/hhfab-dir && cd ~/hhfab-dir
	hhfab init --dev
	hhfab vlab gen
	hhfab build
