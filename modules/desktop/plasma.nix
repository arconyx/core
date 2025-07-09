{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.arcworks.desktop.desktopEnvironment.plasma = {
    enable = lib.mkEnableOption "Plasma 6";
  };

  config =
    let
      cfg = config.arcworks.desktop.desktopEnvironment.plasma;
    in
    lib.mkIf cfg.enable {
      services.desktopManager.plasma6.enable = true;

      # greeter.nix disables our sugar candy theming on Plasma
      config.arcworks.desktop.greeter.sddm.enable = true;

      environment.systemPackages = with pkgs; [
        clinfo
        glxinfo
        wayland-utils
        vulkan-tools
      ];

      environment.sessionVariables.NIXOS_OZONE_WL = "1";
    };
}
