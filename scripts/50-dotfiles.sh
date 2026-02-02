#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${REPO_DIR}/config"
DST="${HOME}/.config"

BACKUP_ROOT="${HOME}/.config-backups"
BACKUP_DIR="${BACKUP_ROOT}/$(date +%F_%H%M%S)"

mkdir -p "$DST" "$BACKUP_DIR"

echo "==> Backing up existing configs to $BACKUP_DIR"

for dir in "$SRC"/*; do
  name="$(basename "$dir")"
  if [[ -e "$DST/$name" ]]; then
    cp -a "$DST/$name" "$BACKUP_DIR/"
  fi
done

echo "==> Copying configs into ~/.config"

rsync -a "$SRC/" "$DST/"

echo "==> Configs installed"
echo "==> Backup stored at: $BACKUP_DIR"
