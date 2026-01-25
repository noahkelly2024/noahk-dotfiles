cat > install.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

# ---- helpers ----
log() { printf "\n\033[1m==>\033[0m %s\n" "$*"; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

# ---- prereqs ----
need_cmd curl
need_cmd git

# ---- install Nix (single-user) if missing ----
if ! command -v nix >/dev/null 2>&1; then
  log "Installing Nix (single-user)..."
  sh <(curl -L https://nixos.org/nix/install) --no-daemon
fi

# ---- load nix into this shell ----
if [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
  # shellcheck disable=SC1090
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
elif [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
  # shellcheck disable=SC1091
  . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
else
  echo "Could not find nix profile script to source." >&2
  exit 1
fi

# ---- enable flakes ----
log "Enabling flakes..."
mkdir -p "$HOME/.config/nix"
NIXCONF="$HOME/.config/nix/nix.conf"
touch "$NIXCONF"

if ! grep -q "experimental-features" "$NIXCONF"; then
  echo "experimental-features = nix-command flakes" >> "$NIXCONF"
else
  # Ensure flakes are present even if experimental-features already exists
  if ! grep -q "flakes" "$NIXCONF"; then
    # Append flakes safely
    echo "experimental-features = nix-command flakes" >> "$NIXCONF"
  fi
fi

# ---- apply Home Manager ----
log "Applying Home Manager configuration..."
# Use -b on first run to avoid clobber errors; harmless on later runs
nix run home-manager/master -- switch -b hm-backup --flake ".#noahk"

log "Done."
log "Next: reload Hyprland with: hyprctl reload"
EOF

chmod +x install.sh
