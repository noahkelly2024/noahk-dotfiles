{ config, pkgs, inputs, ... }:

{
  home.username = "noahk";
  home.homeDirectory = "/home/noahk";
  home.stateVersion = "25.05";

  programs.bash.enable = true;
  programs.bash.shellAliases = {
    btw = "echo i use hyprland btw";
    fr  = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles#hyprland-btw";
  };

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

  wayland.windowManager.hyprland = {
    enable = true;

    package = null;
    portalPackage = null;

    plugins = [
      inputs.hyprland_plugins.packages.${pkgs.stdenv.hostPlatform.system}.hyprscrolling
    ];

    extraConfig = builtins.readFile "${inputs.self}/config/hypr/hyprland.conf";
  };

  xdg.configFile."hypr/hyprpaper.conf".source = ./config/hypr/hyprpaper.conf;

  home.file.".config/waybar".source = ./config/waybar;
  home.file.".config/kitty".source  = ./config/kitty;
  home.file.".config/nvim".source   = ./config/nvim;
  home.file.".config/rofi".source   = ./config/rofi;
}

