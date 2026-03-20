{
  config,
  lib,
  ...
}:
let
  cfg = config.arcworks.server;
in
{
  imports = [
    ./switch-fix.nix
  ];

  options.arcworks.server.enable = lib.mkEnableOption "server config";

  config = lib.mkIf cfg.enable {
    # reboot after one second when kernel panics
    boot.kernelParams = [ "panic=1" ];

    # help maintain connections
    systemd.services.tailscaled.restartIfChanged = false;
  };
}
