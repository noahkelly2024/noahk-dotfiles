{ config, pkgs, inputs, ... }:

{
  home.username = "noahk";
  home.homeDirectory = "/home/noahk";
  home.stateVersion = "25.05";

  # Needed for google-chrome + discord (and other unfree pkgs)
  nixpkgs.config.allowUnfree = true;

  programs.bash = {
    enable = true;
    shellAliases = {
      btw = "echo i use hyprland btw";

      # On CachyOS: apply your Home Manager flake
      fr = "cd ~/noahk-dotfiles && nix run home-manager/master -- switch --flake .#noahk";
      frb ="cd ~/noahk-dotfiles && nix run home-manager/master -- switch -b backup --flake .#noahk";
      
      # Fixed chmod: +x (not +X). sudo not needed for files you own.
      backup = "chmod +x ~/noahk-dotfiles/backup.sh && ~/noahk-dotfiles/backup.sh";
    };
  };

  # Packages from your list
  home.packages = with pkgs; [
    wget
    waybar
    git
    gh
    discord
    btop
    hyprpaper
    hyprcursor
    google-chrome
    rofi
    neofetch
    ripgrep
    grim
    slurp
    wl-clipboard
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
    lsof
    tree-sitter
    opencode
  ];

  # If your Home Manager has this option, it's better than just installing nix-ld:
  # programs.nix-ld.enable = true;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    plugins = with pkgs.vimPlugins; [
      lazy-nvim
      nvim-treesitter
    ];
  };

  gtk.enable = true;

  programs.git = {
    enable = true;
    settings = {
      user.name = "noahkelly2024";
      user.email = "noahkelly2024@gmail.com";
      init.defaultBranch = "main";
    };
  };

  programs.rofi.enable = true;

  home.pointerCursor = {
    name = "DMZ-White";
    size = 24;
    package = pkgs.vanilla-dmz;
    gtk.enable = true;
    x11.enable = true;
  };

  # Hyprland: on CachyOS you typically install hyprland/portals via pacman.
  # Keeping package/portalPackage null avoids HM installing its own Hyprland.
  wayland.windowManager.hyprland = {
    enable = true;

    package = null;
    portalPackage = null;

    plugins = [
      inputs.hyprland_plugins.packages.${pkgs.stdenv.hostPlatform.system}.hyprscrolling
    ];

    extraConfig = builtins.readFile "${inputs.self}/config/hypr/hyprland.conf";
  };

  # Hyprpaper config
  xdg.configFile."hypr/hyprpaper.conf".source = ./config/hypr/hyprpaper.conf;

  # Dotfiles
  home.file.".config/waybar".source = ./config/waybar;
  home.file.".config/kitty".source  = ./config/kitty;
  home.file.".config/nvim".source   = ./config/nvim;
  home.file.".config/rofi".source   = ./config/rofi;
}
