# NixOS Dotfiles

This repository contains my full NixOS + Home-Manager + Neovim configuration.

Everything needed to reproduce my system lives here:
- NixOS system config
- Home-Manager user config
- Hyprland, Waybar, Rofi, Kitty, Neovim, etc

---

## Install on a new machine

Clone the repo:

```bash
git clone git@github.com:noahkelly2024/nixos-dotfiles.git
cd nixos-dotfiles
sudo nixos-rebuild boot --flake .#hyprland-btw

reboot

## Aliases
backup - github backup
fr - rebuild
