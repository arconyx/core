{ config, lib, ... }:
{
  options.arcworks.home.hypr.hyprlock = {
    enable = lib.mkOption {
      description = "Enable hyprlock";
      type = lib.types.bool;
      default = config.arcworks.home.hypr.enable;
      example = true;
    };
  };

  config.programs.hyprlock = {
    enable = config.arcworks.home.hypr.hyprlock.enable;

    settings = {

      general = {
        grace = 6;
        ignore_empty_input = true;
        hide_cursor = true;
      };

      input-field = {
        monitor = ""; # all monitors
        size = "250, 60";
        outline_thickness = 2;
        dots_size = 0.2; # Scale of input-field height, 0.2 - 0.8
        dots_spacing = 0.35; # Scale of dots' absolute size, 0.0 - 1.0
        dots_center = true;
        outer_color = "rgba(0, 0, 0, 0)";
        inner_color = "rgba(0, 0, 0, 0.2)";
        fade_on_empty = true;
        rounding = -1;
        check_color = "rgb(204, 136, 34)";
        # placeholder_text = ''<i><span foreground="##cdd6f4">Password</span></i>'';
        hide_input = false;
        position = "0, -200";
        halign = "center";
        valign = "center";
      };

      background = {
        path = "~/Pictures/wallpaper.jpg";
        blur_passes = 3;
        color = "rgb(126, 182, 189)";
      };

      label = [
        # DATE
        {
          monitor = "";
          text = ''cmd[update:1000] echo "$(date +"%A, %B %d")"'';
          color = "rgba(242, 243, 244, 0.75)";
          font_size = 22;
          position = "0, 300";
          halign = "center";
          valign = "center";
        }
        # TIME
        {
          monitor = "";
          text = "$TIME";
          color = "rgba(242, 243, 244, 0.75)";
          font_size = 95;
          position = "0, 200";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
