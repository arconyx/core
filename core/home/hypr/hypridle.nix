{ config, lib, ... }:
{
  options.arcworks.home.hypr.hypridle = {
    enable = lib.mkOption {
      description = "Enable hypridle";
      type = lib.types.bool;
      default = config.arcworks.home.hypr.enable;
      example = true;
    };
  };

  config =
    let
      cfg = config.arcworks.home.hypr.hypridle;
    in
    {
      services.hypridle = {
        enable = cfg.enable;
        settings = {
          general = {
            lock_cmd = "pidof hyprlock || hyprlock "; # avoid starting multiple hyprlock instances.
            before_sleep_cmd = "loginctl lock-session"; # lock before suspend.
            after_sleep_cmd = "hyprctl dispatch dpms on"; # to avoid having to press a key twice to turn on the display.
          };
          listener = [
            # dim screen
            {
              timeout = 150; # seconds (2.5 min)
              on-timeout = "brightnessctl -s set 10"; # set monitor backlight to minimum, avoid 0 on OLED monitor.
              on-resume = "brightnessctl -r"; # monitor backlight restore.
            }

            # lock
            {
              timeout = 300; # 5min
              on-timeout = "loginctl lock-session"; # lock screen when timeout has passed
            }

            # screen off
            {
              timeout = 420; # 8min
              on-timeout = "hyprctl dispatch dpms off"; # screen off when timeout has passed
              on-resume = "hyprctl dispatch dpms on"; # screen on when activity is detected after timeout has fired.
            }

            # keyboard backlight
            # {
            #   timeout = 150; # 2.5min.
            #   on-timeout = "brightnessctl -sd rgb:kbd_backlight set 0"; # turn off keyboard backlight.
            #   on-resume = "brightnessctl -rd rgb:kbd_backlight"; # turn on keyboard backlight.
            # }

            # sleep
            # {
            #   timeout = 1800; # 30min
            #   on-timeout = "systemctl suspend"; # suspend pc
            # }
          ];
        };
      };

      # TODO: Remove after fix verified
      # Fixes issue with hypridle starting early
      # See https://github.com/nix-community/home-manager/issues/5899#issuecomment-2498226238
      # Can be removed once https://github.com/nix-community/home-manager/pull/6253 hits stable
      # Also affects hyprpaper and waybar
      # systemd.user.services.hypridle.Unit.After = lib.mkForce "graphical-session.target";
    };

}
