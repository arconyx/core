{ config, ... }:
{
  imports = [
    ./desktop
    ./network
    ./server
    ./services

    ./systemd-boot.nix
  ];

  config = {
    assertions = [
      {
        assertion = config.arcworks.desktop.enable != config.arcworks.server.enable;
        message = "Exactly one of arcworks.desktop.enable and arcworks.server.enable must be true";
      }
    ];

    arcworks.systemd-boot.enable = true;
  };
}
