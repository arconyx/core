{
  config,
  lib,
  ...
}:
let
  cfg = config.arcworks.network.tailnet;
in
{
  options.arcworks.network.tailnet.enable = lib.mkEnableOption "joining tailnet";

  config = lib.mkIf cfg.enable {
    # Preferred by tailscale, though it shouldn't make a noticable difference to end users
    # https://tailscale.com/blog/sisyphean-dns-client-linux
    services.resolved.enable = true;

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
