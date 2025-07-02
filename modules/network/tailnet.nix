{
  config,
  lib,
  ...
}:
{
  options.arcworks.network.tailnet.enable = lib.mkEnableOption "joining tailnet";

  config =
    let
      cfg = config.arcworks.network.tailnet;
    in
    lib.mkIf cfg.enable {
      services.tailscale = {
        enable = true;
        extraSetFlags = [
          "--ssh"
          "--webclient"
        ];
        permitCertUid = lib.mkIf config.services.caddy.enable "caddy";
      };
    };
}
