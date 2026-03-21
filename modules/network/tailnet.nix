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

    # https://tailscale.com/docs/features/firewall-mode
    systemd.services.tailscaled.environment.TS_DEBUG_FIREWALL_MODE =
      lib.mkIf config.networking.nftables.enable "auto";
    # The standard nixos firewall blocks connections to local ports over tailscale if
    # we don't mark the interface as trusted
    networking.firewall.trustedInterfaces = lib.mkIf config.networking.nftables.enable [ "tailscale0" ];

    systemd.network.wait-online.ignoredInterfaces = [ "tailscale0" ];

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
