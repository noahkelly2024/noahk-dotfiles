#!/usr/bin/env bash
set -euo pipefail

# Ensure cursor config dirs exist
mkdir -p "$HOME/.config/gtk-3.0"
mkdir -p "$HOME/.icons/default"

# GTK cursor theme (GTK3)
GTK3_FILE="$HOME/.config/gtk-3.0/settings.ini"
if [[ ! -f "$GTK3_FILE" ]]; then
  cat > "$GTK3_FILE" <<'EOF'
[Settings]
EOF
fi

# Update/append values safely
grep -q '^gtk-cursor-theme-name=' "$GTK3_FILE" \
  && sed -i 's/^gtk-cursor-theme-name=.*/gtk-cursor-theme-name=DMZ-White/' "$GTK3_FILE" \
  || echo 'gtk-cursor-theme-name=DMZ-White' >> "$GTK3_FILE"

grep -q '^gtk-cursor-theme-size=' "$GTK3_FILE" \
  && sed -i 's/^gtk-cursor-theme-size=.*/gtk-cursor-theme-size=24/' "$GTK3_FILE" \
  || echo 'gtk-cursor-theme-size=24' >> "$GTK3_FILE"

# Xcursor settings for Wayland/Xwayland apps
XRES="$HOME/.Xresources"
touch "$XRES"
grep -q '^Xcursor.theme:' "$XRES" \
  && sed -i 's/^Xcursor\.theme:.*/Xcursor.theme: DMZ-White/' "$XRES" \
  || echo 'Xcursor.theme: DMZ-White' >> "$XRES"

grep -q '^Xcursor.size:' "$XRES" \
  && sed -i 's/^Xcursor\.size:.*/Xcursor.size: 24/' "$XRES" \
  || echo 'Xcursor.size: 24' >> "$XRES"

# Optional: set default cursor symlink (ArchWiki shows similar patterns for Vanilla-DMZ) :contentReference[oaicite:7]{index=7}
cat > "$HOME/.icons/default/index.theme" <<'EOF'
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=DMZ-White
EOF

echo "Cursor configured: DMZ-White @ 24"
echo "You may need to re-login for all apps to pick it up."
