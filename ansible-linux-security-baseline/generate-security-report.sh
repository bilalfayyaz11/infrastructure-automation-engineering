#!/usr/bin/env bash

set -euo pipefail

REPORT_FILE="/tmp/security-compliance-report.txt"

{
  echo "============================================================"
  echo "LINUX SECURITY COMPLIANCE REPORT"
  echo "============================================================"
  echo "Generated: $(date --iso-8601=seconds)"
  echo "Hostname: $(hostname)"
  echo "Operating system: $(. /etc/os-release && echo "$PRETTY_NAME")"
  echo "Kernel: $(uname -r)"
  echo

  echo "===== SSH EFFECTIVE CONFIGURATION ====="
  sudo sshd -T \
    | grep -E \
      '^(permitrootlogin|passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication|permitemptypasswords|maxauthtries|clientaliveinterval|clientalivecountmax|x11forwarding|allowtcpforwarding|allowagentforwarding|logingracetime|maxsessions|usedns) '
  echo

  echo "===== SSH SERVICE ====="
  systemctl is-active ssh
  systemctl is-enabled ssh
  echo

  echo "===== FIREWALL STATUS ====="
  sudo ufw status verbose
  echo

  echo "===== FAIL2BAN STATUS ====="
  sudo fail2ban-client status
  sudo fail2ban-client status sshd
  echo

  echo "===== AUTOMATIC UPDATE CONFIGURATION ====="
  sudo cat /etc/apt/apt.conf.d/20auto-upgrades
  echo

  echo "===== LISTENING SERVICES ====="
  sudo ss -lntup
  echo

  echo "===== HIGH-RISK PORT CHECK ====="
  if sudo ss -lntup \
    | grep -E ':(23|135|139|445|1433|3389)\b'
  then
    echo "FAIL: High-risk listening port detected"
  else
    echo "PASS: No listed high-risk ports are listening"
  fi
  echo

  echo "===== SENSITIVE FILE PERMISSIONS ====="
  sudo stat -c \
    'Path: %n | Owner: %U:%G | Permissions: %a' \
    /etc/ssh/sshd_config \
    /etc/shadow \
    /etc/gshadow
  echo

  echo "===== RECENT AUTHENTICATION EVENTS ====="
  sudo grep -Ei \
    'failed|failure|invalid user|authentication error' \
    /var/log/auth.log \
    | tail -20 \
    || echo "No recent matching authentication failures"
  echo

  echo "===== AVAILABLE PACKAGE UPDATES ====="
  apt list --upgradable 2>/dev/null \
    | head -20
  echo

  echo "============================================================"
  echo "SECURITY REPORT COMPLETE"
  echo "============================================================"
} | tee "$REPORT_FILE"

sudo install \
  -o root \
  -g root \
  -m 0644 \
  "$REPORT_FILE" \
  /var/log/security-compliance-report.log

echo
echo "Report installed at:"
echo "/var/log/security-compliance-report.log"
