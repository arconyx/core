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
}
