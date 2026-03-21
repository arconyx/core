{ config, ... }:
{
  imports = [
    ./tailnet.nix
    ./homeLan.nix
  ];

  # Firewall is enabled by default but we'll be explicit
  networking.firewall.enable = true;
  # use nftables may cause problems with docker but 0.29
  # includes unstable nfttables support and future stable
  # releases should ship it
  # and it's not like we use docker anyway
  networking.nftables.enable = true;

  services.openssh = {
    # disable ssh when on tailnet
    enable = !config.arcworks.network.tailnet.enable;
    # always configure securely
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };
}
