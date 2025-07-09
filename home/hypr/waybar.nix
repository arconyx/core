{ config, lib, ... }:
{
  options.arcworks.home.hypr.waybar = {
    enable = lib.mkOption {
      description = "Enable hyprlock";
      type = lib.types.bool;
      default = config.arcworks.home.hypr.enable;
      example = true;
    };
  };

  config.programs.waybar = {
    enable = config.arcworks.home.hypr.waybar.enable;
    systemd.enable = config.arcworks.home.hypr.waybar.enable;
    style = ./waybar.css;

    settings = {
      mainBar = {
        position = "right";
        width = 15;
        spacing = 4;
        margin = "2";
        modules-left = [ "clock" ];
        modules-center = [ "hyprland/workspaces" ];
        modules-right = [
          "custom/backup_status"
          "tray"
          "pulseaudio"
          "network"
          "network#tailscale"
          "upower"
        ];
        tray = {
          spacing = 10;
        };
        clock = {
          format = "{:%H\n%M}";
          tooltip-format = "<big>{:%A %d %B %Y}</big>\n<tt><small>{calendar}</small></tt>";
        };
        network = {
          format-wifi = "";
          format-ethernet = "";
          tooltip-format = "{ifname}: {ipaddr}/{cidr}";
          format-linked = "";
          format-disconnected = "⚠";
        };
        "network#tailscale" = {
          interface = "tailscale*";
          format-ethernet = "";
          tooltip-format = "{ifname}: {ipaddr}/{cidr}";
          format-linked = "";
          format-disconnected = "⚠";
        };
        pulseaudio = {
          format = "{icon}";
          tooltip-format = "{desc}\n{volume}%";
          format-bluetooth = "{icon}";
          format-bluetooth-muted = "\n{icon}";
          format-muted = "";
          format-source = "";
          format-source-muted = "";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = [
              ""
              ""
              ""
            ];
          };
        };
        "hyprland/window" = {
          rotate = 270;
        };
        # TODO: parameterise restic integration
        "custom/backup_status" = lib.mkIf {
          exec = "bash -c 'if systemctl is-failed --quiet restic-backups-backblaze.service; then echo \"{\\\"text\\\": \\\"\\\", \\\"tooltip\\\": \\\"Restic backup failed\\\", \\\"class\\\": \\\"failed\\\"}\"; fi'";
          interval = 10;
          format = "{}";
          tooltip = true;
          return-type = "json";
        };
        upower = {
          native-path = "BAT0";
          icon-size = 15;
          hide-if-empty = true;
          show-icon = false;
          tooltip = false;
          tooltip-spacing = 20;
          format = "{percentage}";
          rotate = 270;
        };
      };
    };
  };
}
