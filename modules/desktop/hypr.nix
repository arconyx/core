{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.arcworks.desktop.desktopEnvironment.hypr = {
    enable = lib.mkEnableOption "hyprland";
  };

  config =
    let
      cfg = config.arcworks.desktop.desktopEnvironment.hypr;
    in
    lib.mkIf cfg.enable {
      programs.hyprland = {
        enable = true;
        withUWSM = true;
        xwayland.enable = true;
      };

      # Needed for hyprlock to use PAM to authenticate
      security.pam.services.hyprlock = { };

      environment.systemPackages = with pkgs; [
        hyprpolkitagent
        fontconfig
      ];

      systemd.user.services.hyprpolkitagent = {
        description = "Hyprland Polkit Authentication Agent";
        partOf = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        restartTriggers = [ pkgs.hyprpolkitagent ];
        unitConfig = {
          ConditionEnvironment = "WAYLAND_DISPLAY";
        };
        serviceConfig = {
          ExecStart = ''${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent'';
          Slice = ''session.slice'';
          TimeoutStopSec = "5sec";
          Restart = "on-failure";
        };
      };

      # Flag that we're running under wayland
      # Used for electron apps and stuff
      environment.sessionVariables.NIXOS_OZONE_WL = "1";

      # Explicitly enable QT because the Hyprland module won't
      qt = {
        enable = true;
        style = "adwaita";
      };
    };
}
