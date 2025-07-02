{ config, lib, ... }:

{
  options.arcworks.home.hypr.hyprpaper = {
    enable = lib.mkOption {
      description = "Enable hyprpaper";
      type = lib.types.bool;
      default = config.arcworks.home.hypr.enable;
      example = true;
    };
  };

  config.services.hyprpaper = {
    enable = config.arcworks.home.hypr.hyprpaper.enable;
    settings = {
      preload = "~/Pictures/wallpaper.jpg";
      wallpaper = ",~/Pictures/wallpaper.jpg";
    };
  };

  # TODO: Remove after testing
  # Fixes issue with hyprpaper starting early
  # See https://github.com/nix-community/home-manager/issues/5899#issuecomment-2498226238
  # Can be removed once https://github.com/nix-community/home-manager/pull/6253 hits stable
  # Also affects hypridle and waybar
  # systemd.user.services.hyprpaper.Unit.After = lib.mkForce "graphical-session.target";
}
