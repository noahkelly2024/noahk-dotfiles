{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.kernelModules = [ "amdgpu" ];

  networking.hostName = "noahk-nixos";
  networking.networkmanager.enable = true;

  time.timeZone = "America/New_York";

  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.displayManager.defaultSession = "hyprland";
  services.seatd.enable = true;
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "noahk";

  services.pipewire.enable = false;
  services.pulseaudio.enable = true;

  users.users.noahk = {
    isNormalUser = true;
    description = "Noah Kelly";
    extraGroups = [ "networkmanager" "wheel" "video" "input" "audio" "render" ];
    packages = with pkgs; [];
  };

  nixpkgs.config.allowUnfree = true;

  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  environment.systemPackages = with pkgs; [
    wget
    kitty
    waybar
    git
    gh
    btop
    hyprpaper
    hyprcursor
    google-chrome
    rofi
    neovim
    neofetch
    ripgrep
    grim
    slurp
    wl-clipboard
    vanilla-dmz
    fd
    bat
    file
    pavucontrol
    playerctl
    coreutils
    lazygit
    cargo
    rustc
    nodejs
    gcc
    nix-ld
    python3
    unzip
    nodejs_22
    lsof
    opencode
  ];

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "25.11";
}
