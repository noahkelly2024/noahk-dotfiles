#!/usr/bin/env bash
set -euo pipefail

# ---------------- helpers ----------------
log() { printf "\n\033[1m==>\033[0m %s\n" "$*"; }
err() { printf "\n\033[1;31mERROR:\033[0m %s\n" "$*" >&2; }
need_cmd() { command -v "$1" >/dev/null 2>&1 || { err "Missing command: $1"; exit 1; }; }

read_pkg_list() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  grep -vE '^\s*#|^\s*$' "$f" || true
}

# ---------------- resolve repo root ----------------
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd -- "$(dirname -- "$SCRIPT_PATH")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

CONFIG_SRC="$REPO_DIR/config"
PACMAN_LIST="$CONFIG_SRC/pacman-packages.txt"
AUR_LIST="$CONFIG_SRC/aur-packages.txt"

if [[ ! -d "$CONFIG_SRC" ]]; then
  err "Config directory not found: $CONFIG_SRC"
  exit 1
fi

# ---------------- determine target user ----------------
# If run with sudo, target is SUDO_USER; otherwise it's current user.
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(eval echo "~$TARGET_USER")"

if [[ -z "${TARGET_HOME}" || ! -d "${TARGET_HOME}" ]]; then
  err "Target home not found for user '$TARGET_USER' (resolved: '$TARGET_HOME')."
  err "Fix the user/home or run as the correct user."
  exit 1
fi

# Run commands as the target user.
run_as_user() {
  if [[ "${EUID}" -eq 0 ]]; then
    # Running as root: drop to user.
    sudo -u "$TARGET_USER" -H env \
      HOME="$TARGET_HOME" \
      XDG_CONFIG_HOME="$TARGET_HOME/.config" \
      XDG_DATA_HOME="$TARGET_HOME/.local/share" \
      XDG_CACHE_HOME="$TARGET_HOME/.cache" \
      bash -lc "$*"
  else
    # Running as user already.
    env \
      HOME="$TARGET_HOME" \
      XDG_CONFIG_HOME="$TARGET_HOME/.config" \
      XDG_DATA_HOME="$TARGET_HOME/.local/share" \
      XDG_CACHE_HOME="$TARGET_HOME/.cache" \
      bash -lc "$*"
  fi
}

need_cmd sudo
sudo -v
while true; do sudo -n true; sleep 30; kill -0 "$$" || exit; done 2>/dev/null &

# ---------------- hard-fix permissions ----------------
log "Fixing permissions for $TARGET_USER (repo + cache dirs)..."
sudo mkdir -p "$TARGET_HOME/.cache" "$TARGET_HOME/.config" "$TARGET_HOME/.local/share"
sudo chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.cache" "$TARGET_HOME/.config" "$TARGET_HOME/.local" "$REPO_DIR" 2>/dev/null || true

# ---------------- pacman steps (root) ----------------
log "Updating package databases..."
sudo pacman -Sy --noconfirm

log "Installing pacman packages from: $PACMAN_LIST"
PACMAN_PKGS="$(read_pkg_list "$PACMAN_LIST" | tr '\n' ' ')"
if [[ -n "${PACMAN_PKGS// }" ]]; then
  sudo pacman -S --needed --noconfirm ${PACMAN_PKGS}
else
  log "No pacman packages to install (file missing or empty)."
fi

# Ensure required tools exist even if lists are missing/wrong
log "Ensuring required tools..."
sudo pacman -S --needed --noconfirm rsync github-cli base-devel git

# ---------------- ensure paru ----------------
log "Ensuring AUR helper (paru)..."
if ! command -v paru >/dev/null 2>&1; then
  if sudo pacman -S --needed --noconfirm paru; then
    :
  else
    log "paru not in repos; building from AUR as $TARGET_USER..."
    run_as_user "
      set -euo pipefail
      tmp=\$(mktemp -d)
      git clone https://aur.archlinux.org/paru.git \"\$tmp/paru\"
      cd \"\$tmp/paru\"
      makepkg -si --noconfirm
      rm -rf \"\$tmp\"
    "
  fi
fi
need_cmd paru

# ---------------- AUR install with /tmp cache/build (avoids broken HOME) ----------------
log "Installing AUR packages from: $AUR_LIST (as $TARGET_USER, using /tmp)..."
AUR_PKGS="$(read_pkg_list "$AUR_LIST" | tr '\n' ' ')"
if [[ -n "${AUR_PKGS// }" ]]; then
  # Put paru cache + makepkg build dir in /tmp to avoid permission/home issues
  run_as_user "
    set -euo pipefail
    export TMPDIR=/tmp
    export XDG_CACHE_HOME=/tmp/xdg-cache-$TARGET_USER
    export PARU_CACHE_DIR=/tmp/paru-cache-$TARGET_USER
    export BUILDDIR=/tmp/makepkg-build-$TARGET_USER
    mkdir -p \"\$XDG_CACHE_HOME\" \"\$PARU_CACHE_DIR\" \"\$BUILDDIR\"
    paru -S --needed --noconfirm ${AUR_PKGS}
  "
else
  log "No AUR packages to install (file missing or empty)."
fi

# ---------------- git identity + gh auth (user) ----------------
log "Configuring git identity (as $TARGET_USER)..."
run_as_user "git config --global user.name 'noahkelly2024'"
run_as_user "git config --global user.email 'noahkelly2024@gmail.com'"
run_as_user "git config --global init.defaultBranch main"
run_as_user "git config --global pull.rebase true"

log "Verifying GitHub authentication via gh (as $TARGET_USER)..."
if run_as_user "gh auth status >/dev/null 2>&1"; then
  log "GitHub already authenticated via gh."
else
  log "GitHub not authenticated. Starting gh login..."
  run_as_user "gh auth login --git-protocol ssh --hostname github.com"
fi

log "Ensuring repo remote uses SSH..."
if run_as_user "git -C '$REPO_DIR' remote -v | grep -q 'https://github.com'"; then
  run_as_user "
    repo_path=\$(git -C '$REPO_DIR' remote get-url origin | sed -E 's#https://github.com/##; s#\.git$##')
    git -C '$REPO_DIR' remote set-url origin \"git@github.com:\${repo_path}.git\"
  "
fi

# ---------------- copy configs (user) ----------------
log "Copying configs to ~/.config (with backup) as $TARGET_USER..."
run_as_user "
  set -euo pipefail
  CONFIG_DST=\"$TARGET_HOME/.config\"
  mkdir -p \"\$CONFIG_DST\"

  BACKUP_ROOT=\"$TARGET_HOME/.config-backups\"
  BACKUP_DIR=\"\$BACKUP_ROOT/\$(date +%F_%H%M%S)\"
  mkdir -p \"\$BACKUP_DIR\"

  for d in '$CONFIG_SRC'/*; do
    name=\"\$(basename \"\$d\")\"
    [[ \"\$name\" == 'pacman-packages.txt' || \"\$name\" == 'aur-packages.txt' ]] && continue
    if [[ -e \"\$CONFIG_DST/\$name\" ]]; then
      cp -a \"\$CONFIG_DST/\$name\" \"\$BACKUP_DIR/\" || true
    fi
  done

  rsync -a \
    --exclude 'pacman-packages.txt' \
    --exclude 'aur-packages.txt' \
    '$CONFIG_SRC/' \"\$CONFIG_DST/\"

  echo \"Configs copied. Backup at: \$BACKUP_DIR\"
"

# ---------------- aliases (user) ----------------
log "Adding shell aliases to ~/.bashrc as $TARGET_USER..."
run_as_user "
  set -euo pipefail
  BASHRC=\"$TARGET_HOME/.bashrc\"
  touch \"\$BASHRC\"
  ensure_line() { grep -qxF \"\$1\" \"\$BASHRC\" 2>/dev/null || echo \"\$1\" >> \"\$BASHRC\"; }

  ensure_line \"\"
  ensure_line \"# --- noahk-dotfiles aliases ---\"
  ensure_line \"alias btw='echo i use hyprland btw'\"
  ensure_line \"alias backup='chmod +x \\\"$REPO_DIR/scripts/backup.sh\\\" && \\\"$REPO_DIR/scripts/backup.sh\\\"'\"
  ensure_line \"# --- end noahk-dotfiles aliases ---\"
"

# ---------------- optional scripts ----------------
if [[ -x "$REPO_DIR/scripts/60-services.sh" ]]; then
  log "Running services script (as $TARGET_USER)..."
  run_as_user "\"$REPO_DIR/scripts/60-services.sh\"" || true
fi

if [[ -x "$REPO_DIR/scripts/70-desktop.sh" ]]; then
  log "Running desktop script (as $TARGET_USER)..."
  run_as_user "\"$REPO_DIR/scripts/70-desktop.sh\"" || true
fi

log "Setup complete 🎉"
echo "Next steps:"
echo "  - Re-login (recommended)"
echo "  - Or reload Hyprland: hyprctl reload"
echo "  - New shell for aliases: exec bash"
