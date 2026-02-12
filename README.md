# Omarchy Dotfiles (Work In Progress)

This repository contains my full Omarchy + Neovim configuration.

Everything needed to reproduce my system lives here:
- Hyprland, Waybar, Rofi, Kitty, Neovim, etc

---

## Install on a new machine


## Windows VM:
# 1. Fetch PR branch
git -C "$OMARCHY_PATH" fetch origin pull/3454/head
git -C "$OMARCHY_PATH" checkout -B feat/omarchy-gpu-passthrough FETCH_HEAD

# 2. Switch to test branch
omarchy-update-branch feat/omarchy-gpu-passthrough

# 3. Test features
omarchy-gpu-passthrough info detect    # Check hardware compatibility
omarchy-gpu-passthrough setup          # Run setup (backs up config files)
sudo reboot                            # Apply kernel parameters

# 4. Verify configuration (after reboot)
omarchy-gpu-passthrough info verify    # Check everything is configured correctly

# Optional: generate reports (helpful for troubleshooting)
omarchy-gpu-passthrough info report    # Hardware configuration summary
omarchy-gpu-passthrough info diagnose  # Full diagnostic report

# 5. Install Windows VM
omarchy-windows-vm install             # Install Windows VM with Looking Glass

# 6. Optimize Windows VM
Inside of windows:
Install wait for GPU drivers to install
disable the VirtIO gpu
Install Virtual Display Driver and set it as main display to adjust refresh rate
Fix Lag and CPU overhead: bcdedit /set disabledynamictick yes
reboot

# 7. Return to master (Maybe)
omarchy-update-branch master
git -C "$OMARCHY_PATH" branch -D feat/omarchy-gpu-passthrough
