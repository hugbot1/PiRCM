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
DEBIAN_FRONTEND=noninteractive apt-get install -y git build-essential make usbutils

echo "[PiRCM] Creating directories..."
install -d -m 0755 "$APP_DIR" "$APP_DIR/payloads" "$ETC_DIR"

echo "[PiRCM] Fetching fusee-nano..."
if [[ -d "$APP_DIR/fusee-nano/.git" ]]; then
  git -C "$APP_DIR/fusee-nano" pull --ff-only
else
  git clone --depth 1 "$UPSTREAM" "$APP_DIR/fusee-nano"
fi

echo "[PiRCM] Building fusee-nano..."
make -C "$APP_DIR/fusee-nano"

if [[ ! -x "$APP_DIR/fusee-nano/fusee-nano" ]]; then
  echo "Build did not produce $APP_DIR/fusee-nano/fusee-nano" >&2
  exit 1
fi

install -m 0755 "$REPO_DIR/src/pircm-watch" "$BIN_DIR/pircm-watch"
install -m 0755 "$REPO_DIR/src/pircm-select" "$BIN_DIR/pircm-select"
install -m 0755 "$REPO_DIR/src/pircm-doctor" "$BIN_DIR/pircm-doctor"
install -m 0644 "$REPO_DIR/systemd/pircm.service" "$SERVICE_DIR/pircm.service"

if [[ ! -f "$ETC_DIR/pircm.conf" ]]; then
  install -m 0644 "$REPO_DIR/config/pircm.conf" "$ETC_DIR/pircm.conf"
fi

if [[ ! -f "$APP_DIR/payloads/README.txt" ]]; then
  cat > "$APP_DIR/payloads/README.txt" <<'EOF'
Place your own legally obtained Nintendo Switch RCM .bin payloads in this folder.
Select one with: sudo pircm-select filename.bin
EOF
  chmod 0644 "$APP_DIR/payloads/README.txt"
fi

systemctl daemon-reload
systemctl enable --now pircm.service

echo
echo "[PiRCM] Installation complete."
echo "1. Copy a .bin payload into $APP_DIR/payloads/"
echo "2. Select it with: sudo pircm-select filename.bin"
echo "3. View logs with: sudo journalctl -u pircm -f"
echo "4. Run checks with: sudo pircm-doctor"
