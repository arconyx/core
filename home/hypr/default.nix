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
    darkTheme = lib.mkEnableOption "dark theme";
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

      gtk =
        {
          enable = true;
          cursorTheme = {
            package = pkgs.rose-pine-cursor;
            name = "BreezeX-RosePine-Linux";
            size = 24; # TODO: merge with home.pointerCursor.size
          };
          theme = {
            name = "Adwaita";
            # setting package to null uses the default I think?
            # which is adwaita dark
            # Ah, ctrl-f for adwaita in here https://gitlab.gnome.org/GNOME/gtk/-/blob/036d084561e50ba33d0dff1a0713bd14d68f6cea/gtk/gtkcssprovider.c
            package = null;
          };
          iconTheme = {
            name = "Adwaita";
            package = pkgs.adwaita-icon-theme;
          };
        }
        // lib.optionalAttrs cfg.darkTheme {
          theme.name = "Adwaita-dark";
          # gtk4.extraConfig = { gtk-interface-color-scheme = false; }; v4.20+
          gtk4.extraConfig = {
            gtk-application-prefer-dark-theme = true;
          }; # deprecated in 4.20
          gtk3.extraConfig = {
            gtk-application-prefer-dark-theme = true;
          };
        };

      dconf.enable = true;
      dconf.settings = lib.mkIf cfg.darkTheme {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
        };
        "org/freedesktop/appearance" = {
          color-scheme = 1; # 0 = no pref; 1 = dark; 2 = light
        };
      };

      qt =
        {
          enable = true;
          style.name = "adwaita";
          platformTheme.name = "adwaita";
        }
        // lib.optionalAttrs cfg.darkTheme {
          style.name = "adwaita-dark";
          platformTheme.name = "qtct";
        };

      xdg.portal.enable = true; # Paths have been linked in users.nix as requested by option description
      xdg.portal.extraPortals = [
        pkgs.xdg-desktop-portal-hyprland
        pkgs.xdg-desktop-portal-gtk
      ];

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
