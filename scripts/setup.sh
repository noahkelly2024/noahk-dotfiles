#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

# ---------------- helpers ----------------
log() { printf "\n\033[1m==>\033[0m %s\n" "$*"; }
err() { printf "\n\033[1;31mERROR:\033[0m %s\n" "$*" >&2; }
need_cmd() { command -v "$1" >/dev/null 2>&1 || {
  err "Missing command: $1"
  exit 1
}; }

is_installed_pacman() { pacman -Qq "$1" >/dev/null 2>&1; }

read_pkg_list() {
  # reads a file and prints pkgs line-by-line, ignoring blanks/comments
  local f="$1"
  [[ -f "$f" ]] || return 0
  grep -vE '^\s*#|^\s*$' "$f" || true
}

# ---------------- prereqs ----------------
need_cmd bash
need_cmd git
need_cmd sudo

# keep sudo alive
sudo -v
while true; do
  sudo -n true
  sleep 30
  kill -0 "$$" || exit
done 2>/dev/null &

# ---------------- git identity ----------------
log "Configuring git identity..."
git config --global user.name "noahkelly2024"
git config --global user.email "noahkelly2024@gmail.com"
git config --global init.defaultBranch main
git config --global pull.rebase true

# ---------------- git ssh setup ----------------
log "Setting up Git SSH authentication..."
need_cmd ssh
need_cmd ssh-keygen

SSH_DIR="$HOME/.ssh"
SSH_KEY="$SSH_DIR/id_ed25519"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

if [[ ! -f "$SSH_KEY" ]]; then
  log "Generating SSH key (ed25519)..."
  ssh-keygen -t ed25519 -C "noahkelly2024@$(hostname)" -f "$SSH_KEY" -N ""
else
  log "SSH key already exists."
fi

# Start ssh-agent if not running
if ! pgrep -u "$USER" ssh-agent >/dev/null 2>&1; then
  eval "$(ssh-agent -s)"
fi

ssh-add "$SSH_KEY" >/dev/null 2>&1 || true

echo
echo "👉 Add this SSH key to GitHub:"
echo "----------------------------------------"
cat "${SSH_KEY}.pub"
echo "----------------------------------------"
echo
echo "GitHub → Settings → SSH and GPG keys → New SSH key"
echo "Press Enter once added to continue..."
read -r

log "Testing GitHub SSH connection..."
if ssh -T git@github.com 2>&1 | grep -qi "successfully authenticated"; then
  log "GitHub SSH authentication successful."
else
  echo
  echo "⚠️  SSH test did not confirm success."
  echo "You can re-test later with: ssh -T git@github.com"
fi

# ---------------- paths ----------------
PACMAN_LIST="$REPO_DIR/config/pacman-packages.txt"
AUR_LIST="$REPO_DIR/config/aur-packages.txt"
CONFIG_SRC="$REPO_DIR/config"
CONFIG_DST="$HOME/.config"

# ---------------- remove nix (if present) ----------------
log "Removing Nix (if installed)..."
if command -v nix >/dev/null 2>&1 || [[ -d /nix ]] || [[ -d /etc/nix ]]; then
  if systemctl list-unit-files 2>/dev/null | grep -q '^nix-daemon\.service'; then
    sudo systemctl disable --now nix-daemon.service || true
  fi

  sudo rm -rf /etc/nix /nix || true
  rm -rf "$HOME/.nix-profile" "$HOME/.nix-defexpr" "$HOME/.nix-channels" || true

  for f in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile" "$HOME/.bash_profile"; do
    [[ -f "$f" ]] || continue
    sed -i \
      -e '/nix\/profile/d' \
      -e '/\.nix-profile/d' \
      -e '/nix-daemon/d' \
      -e '/nix.sh/d' \
      -e '/\/nix\//d' \
      "$f" || true
  done
  log "Nix removed (best-effort). Open a new shell after setup."
else
  log "Nix not detected. Skipping."
fi

# ---------------- system update ----------------
log "Updating package databases..."
sudo pacman -Sy --noconfirm

# ---------------- pacman packages ----------------
log "Installing pacman packages from: $PACMAN_LIST"
PACMAN_PKGS="$(read_pkg_list "$PACMAN_LIST" | tr '\n' ' ')"
if [[ -n "${PACMAN_PKGS// /}" ]]; then
  sudo pacman -S --needed --noconfirm ${PACMAN_PKGS}
else
  log "No pacman packages found (file missing or empty)."
fi

# ---------------- AUR helper ----------------
log "Ensuring AUR helper (paru)..."
if ! command -v paru >/dev/null 2>&1; then
  if is_installed_pacman paru; then
    log "paru package appears installed but not on PATH (unexpected)."
  else
    if sudo pacman -S --needed --noconfirm paru; then
      :
    else
      log "paru not in repos; building from AUR..."
      sudo pacman -S --needed --noconfirm base-devel git
      tmp="$(mktemp -d)"
      git clone https://aur.archlinux.org/paru.git "$tmp/paru"
      (cd "$tmp/paru" && makepkg -si --noconfirm)
      rm -rf "$tmp"
    fi
  fi
fi
need_cmd paru

# ---------------- AUR packages ----------------
log "Installing AUR packages from: $AUR_LIST"
AUR_PKGS="$(read_pkg_list "$AUR_LIST" | tr '\n' ' ')"
if [[ -n "${AUR_PKGS// /}" ]]; then
  paru -S --needed --noconfirm ${AUR_PKGS}
else
  log "No AUR packages found (file missing or empty)."
fi

# ---------------- configs: copy repo/config -> ~/.config ----------------
log "Copying configs to ~/.config (with backup)..."
mkdir -p "$CONFIG_DST"

BACKUP_ROOT="$HOME/.config-backups"
BACKUP_DIR="$BACKUP_ROOT/$(date +%F_%H%M%S)"
mkdir -p "$BACKUP_DIR"

for d in "$CONFIG_SRC"/*; do
  name="$(basename "$d")"
  [[ "$name" == "pacman-packages.txt" || "$name" == "aur-packages.txt" ]] && continue
  if [[ -e "$CONFIG_DST/$name" ]]; then
    cp -a "$CONFIG_DST/$name" "$BACKUP_DIR/" || true
  fi
done

rsync -a \
  --exclude 'pacman-packages.txt' \
  --exclude 'aur-packages.txt' \
  "$CONFIG_SRC/" "$CONFIG_DST/"

log "Configs copied. Backup at: $BACKUP_DIR"

# ---------------- shell aliases (no nix aliases) ----------------
log "Adding basic aliases (btw, backup)..."
BASHRC="$HOME/.bashrc"
touch "$BASHRC"

ensure_line() {
  local line="$1"
  grep -qxF "$line" "$BASHRC" 2>/dev/null || echo "$line" >>"$BASHRC"
}

ensure_line ""
ensure_line "# --- noahk-dotfiles aliases ---"
ensure_line "alias btw='echo i use hyprland btw'"
ensure_line "alias backup='chmod +x \"$REPO_DIR/scripts/backup.sh\" && \"$REPO_DIR/scripts/backup.sh\"'"
ensure_line "# --- end noahk-dotfiles aliases ---"

# ---------------- run optional extra scripts ----------------
if [[ -x "$REPO_DIR/scripts/60-services.sh" ]]; then
  log "Running services script..."
  "$REPO_DIR/scripts/60-services.sh"
fi

if [[ -x "$REPO_DIR/scripts/70-desktop.sh" ]]; then
  log "Running desktop script..."
  "$REPO_DIR/scripts/70-desktop.sh"
fi

log "Done."
log "Next steps:"
echo "  - Re-login (recommended) so cursor/theme/environment changes apply everywhere."
echo "  - Or reload Hyprland: hyprctl reload"
echo "  - New shell for aliases: exec bash"
