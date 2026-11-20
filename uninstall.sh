#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "${EUID}" -ne 0 ]]; then
    echo "Run with sudo: sudo ./uninstall.sh [--purge]" >&2
    exit 1
fi

PURGE=0
[[ "${1:-}" == "--purge" ]] && PURGE=1

echo "[PiRCM] Stopping service..."
systemctl disable --now pircm.service 2>/dev/null || true

echo "[PiRCM] Removing service and commands..."
rm -f /etc/systemd/system/pircm.service
rm -f /usr/local/bin/pircm-watch
rm -f /usr/local/bin/pircm-select
rm -f /usr/local/bin/pircm-doctor
rm -f /usr/local/bin/pircm-update-hekate

systemctl daemon-reload
systemctl reset-failed

if [[ "$PURGE" -eq 1 ]]; then
    rm -rf /opt/pircm /etc/pircm
    echo "[PiRCM] Completely removed, including payloads and configuration."
else
    rm -rf /opt/pircm/fusee-nano
    echo "[PiRCM] Removed PiRCM software. Payloads and configuration preserved."
fi