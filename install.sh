#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="/opt/pircm"
ETC_DIR="/etc/pircm"
BIN_DIR="/usr/local/bin"
SERVICE_DIR="/etc/systemd/system"
UPSTREAM="https://github.com/DavidBuchanan314/fusee-nano.git"

if [[ "${EUID}" -ne 0 ]]; then
    echo "Run this installer with: sudo ./install.sh" >&2
    exit 1
fi

if ! grep -qiE 'Raspberry Pi 5|BCM2712' /proc/cpuinfo; then
    echo "WARNING: This installer is intended for Raspberry Pi 5. Continuing anyway."
fi

echo "[PiRCM] Installing system packages..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    git build-essential make usbutils xxd curl jq

echo "[PiRCM] Creating directories..."
install -d -m 0755 "$APP_DIR" "$APP_DIR/payloads" "$ETC_DIR"

echo "[PiRCM] Fetching fusee-nano..."
if [[ -d "$APP_DIR/fusee-nano/.git" ]]; then
    git -C "$APP_DIR/fusee-nano" pull --ff-only
elif [[ -e "$APP_DIR/fusee-nano" ]]; then
    echo "Found $APP_DIR/fusee-nano but it is not a Git checkout." >&2
    echo "Move that directory out of the way, then rerun the installer." >&2
    exit 1
else
    git clone --depth 1 "$UPSTREAM" "$APP_DIR/fusee-nano"
fi

echo "[PiRCM] Building fusee-nano (regenerating intermezzo.h)..."
make -C "$APP_DIR/fusee-nano" clean
rm -f "$APP_DIR/fusee-nano/src/intermezzo.h"
make -C "$APP_DIR/fusee-nano"

if [[ ! -x "$APP_DIR/fusee-nano/fusee-nano" ]]; then
    echo "Build did not produce $APP_DIR/fusee-nano/fusee-nano" >&2
    exit 1
fi

echo "[PiRCM] Installing PiRCM commands and service..."
install -m 0755 "$REPO_DIR/src/pircm-watch" "$BIN_DIR/pircm-watch"
install -m 0755 "$REPO_DIR/src/pircm-select" "$BIN_DIR/pircm-select"
install -m 0755 "$REPO_DIR/src/pircm-doctor" "$BIN_DIR/pircm-doctor"
install -m 0755 "$REPO_DIR/src/pircm-update-hekate" "$BIN_DIR/pircm-update-hekate"
install -m 0644 "$REPO_DIR/systemd/pircm.service" "$SERVICE_DIR/pircm.service"

if [[ ! -f "$ETC_DIR/pircm.conf" ]]; then
    install -m 0644 "$REPO_DIR/config/pircm.conf" "$ETC_DIR/pircm.conf"
fi

if [[ ! -f "$APP_DIR/payloads/README.txt" ]]; then
    cat > "$APP_DIR/payloads/README.txt" <<'EOF'
Place Nintendo Switch RCM .bin payloads in this folder.
Select one with: sudo pircm-select filename.bin
Update Hekate with: sudo pircm-update-hekate
EOF
    chmod 0644 "$APP_DIR/payloads/README.txt"
fi

echo "[PiRCM] Enabling the service..."
systemctl daemon-reload
systemctl enable --now pircm.service

echo "[PiRCM] Downloading and selecting the latest official Hekate..."
"$BIN_DIR/pircm-update-hekate"

echo
echo "[PiRCM] Installation complete."
echo "Selected payload: hekate.bin"
echo "Update Hekate any time: sudo pircm-update-hekate"
echo "List payloads:          sudo pircm-select --list"
echo "Select another payload: sudo pircm-select filename.bin"
echo "View logs:              sudo journalctl -u pircm -f"
echo "Run diagnostics:        sudo pircm-doctor"