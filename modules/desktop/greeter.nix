{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.arcworks.desktop.greeter.sddm = {
    enable = lib.mkEnableOption "SDDM";
    background = lib.mkOption {
      type = lib.types.nullOr lib.types.pathInStore;
      default = null;
      description = "Path to background image";
    };
    useSddmTheme = lib.mkOption {
      type = lib.types.bool;
      default = !config.arcworks.desktop.desktopEnvironment.plasma.enable;
      example = "true";
      description = "Use custom SDDM theme (currently sddm-astronaut) instead of default";
    };
  };

  config =
    let
      cfg = config.arcworks.desktop.greeter.sddm;
    in
    lib.mkIf cfg.enable {
      services.displayManager.sddm = {
        enable = true;
        wayland.enable = true;
        autoNumlock = true;
        theme = lib.mkIf cfg.useSddmTheme "sddm-astronaut-theme";
        extraPackages = lib.mkIf cfg.useSddmTheme (with pkgs.kdePackages; [ qtmultimedia ]);
      };

      environment.systemPackages = lib.mkIf cfg.useSddmTheme [
        (
          if cfg.background == null then
            pkgs.sddm-astronaut
          else
            (pkgs.sddm-astronaut.override {
              themeConfig = {
                background = "${cfg.background}";
                PartialBlur = false;
              };
            })
        )
      ];
    };
}
