#!/usr/bin/env bash
set -Eeuo pipefail
if [[ "${EUID}" -ne 0 ]]; then
  echo "Run with sudo: sudo ./uninstall.sh [--purge]" >&2
  exit 1
fi

PURGE=0
[[ "${1:-}" == "--purge" ]] && PURGE=1

systemctl disable --now pircm.service 2>/dev/null || true
rm -f /etc/systemd/system/pircm.service
rm -f /usr/local/bin/pircm-watch /usr/local/bin/pircm-select /usr/local/bin/pircm-doctor
systemctl daemon-reload
systemctl reset-failed

if [[ "$PURGE" -eq 1 ]]; then
  rm -rf /opt/pircm /etc/pircm
  echo "PiRCM and payloads/configuration removed."
else
  rm -rf /opt/pircm/fusee-nano
  echo "PiRCM service removed. Payloads kept in /opt/pircm/payloads and config in /etc/pircm."
fi
