{
  config,
  lib,
  pkgs,
  osConfig,
  ...
}:

{
  imports = [
    ./hyprland.nix
    ./hypridle.nix
    ./hyprlock.nix
    ./hyprpaper.nix
    ./waybar.nix
  ];

  options.arcworks.home.hypr = {
    enable = lib.mkOption {
      description = "Enable hypr home config";
      type = lib.types.bool;
      default = osConfig.arcworks.desktop.desktopEnvironment.hypr.enable;
      example = true;
    };
  };

  config =
    let
      cfg = config.arcworks.home.hypr;
    in
    lib.mkIf cfg.enable {
      home.file = {
        # Set XDG_MENU_PREFIX to fix something or other...
        # ".config/uwsm/env".text = ''
        #   XDG_MENU_PREFIX,plasma-
        #   XCURSOR_SIZE,24
        # '';
      };

      home.packages = with pkgs; [ wl-clipboard ];

      programs.swayimg.enable = true;
      programs.mpv.enable = true;

      programs.rofi = {
        enable = true;
        package = pkgs.rofi-wayland;
        plugins = with pkgs; [
          rofi-bluetooth
          # rofi-calc
          rofi-power-menu
          rofi-systemd
        ];
      };

      home.pointerCursor = {
        package = pkgs.rose-pine-hyprcursor;
        name = "rose-pine-hyprcursor";
        size = 24;
        gtk.enable = true;
      };

      gtk = {
        enable = true;
        cursorTheme = {
          package = pkgs.rose-pine-cursor;
          name = "BreezeX-RosePine-Linux";
          size = 24; # TODO: merge with home.pointerCursor.size
        };
        theme = {
          name = "Adwaita";
          package = pkgs.gnome-themes-extra;
        };
        iconTheme.name = "Adwaita";
      };

      qt = {
        enable = true;
        style.name = "adwaita";
        platformTheme.name = "adwaita";
      };

      xdg.portal.enable = true; # Paths have been linked in users.nix as requested by option description
      xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];

      services.mako = {
        enable = true;
        settings = {
          anchor = "top-right";
          default-timeout = 10000;
          background-color = "#1e1e2e";
          border-color = "#b4befe";
          progress-color = "over #313244";
          text-color = "#cdd6f4";
          "urgency=high" = {
            border-color = "#fab387";
            default-timeout = 0;
          };
        };
      };
    };
}
