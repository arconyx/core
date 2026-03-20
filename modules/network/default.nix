{ config, ... }:
{
  imports = [
    ./tailnet.nix
    ./homeLan.nix
  ];

  # Firewall is enabled by default but we'll be explicit
  networking.firewall.enable = true;

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
