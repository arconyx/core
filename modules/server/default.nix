{ config, lib, ... }:
{
  imports = [
    ./minimal.nix
    ./pi.nix
    ./switch-fix.nix
  ];

  options.arcworks.server = {
    enable = lib.mkEnableOption "server config";
    pi = lib.mkEnableOption "pi zero options";
  };

  config =
    let
      cfg = config.arcworks.server;
    in
    {
      assertions = [
        {
          assertion = (!cfg.pi) || cfg.enable;
          message = "If arcworks.server.pi is true then arcworks.server.enable must be true";
        }
      ];
    }
    // lib.mkIf cfg.enable {
      # reboot after one second when kernel panics
      boot.kernelParams = [ "panic=1" ];

      networking.networkmanager.enable = !cfg.pi;

      # runtime watchdog
      systemd.watchdog.runtimeTime = if cfg.pi then "15s" else "30s";

      # help maintain connections
      systemd.services.tailscaled.restartIfChanged = false;
    };
}
