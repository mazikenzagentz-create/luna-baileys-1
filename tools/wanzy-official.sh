#!/usr/bin/env bash
set -Eeuo pipefail
tmp="$(mktemp /tmp/wanzy-installer.XXXXXX)"
trap 'rm -f "$tmp"' EXIT
curl --fail --location --silent --show-error https://raw.githubusercontent.com/mazikenzagentz-create/luna-baileys-1/main/tools/wanzy-install.sh -o "$tmp"
exec bash "$tmp"
