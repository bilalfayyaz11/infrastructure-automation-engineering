#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="$HOME/ansible-vault-security/vault_files"
BACKUP_ROOT="$HOME/ansible-vault-security/backups"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP_DIR="$BACKUP_ROOT/vault-backup-$TIMESTAMP"

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

cp "$SOURCE_DIR"/*.yml "$BACKUP_DIR/"
chmod 600 "$BACKUP_DIR"/*.yml

cat > "$BACKUP_DIR/manifest.txt" << EOT
Vault Backup Manifest
Created UTC: $TIMESTAMP
Source: $SOURCE_DIR
EOT

(
  cd "$BACKUP_DIR"
  sha256sum ./*.yml > manifest.sha256
)

chmod 600 \
  "$BACKUP_DIR/manifest.txt" \
  "$BACKUP_DIR/manifest.sha256"

echo "$BACKUP_DIR"
