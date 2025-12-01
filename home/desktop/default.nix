{
  osConfig,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./kitty.nix
    ./laptop.nix
  ];

  config = lib.mkIf osConfig.arcworks.desktop.enable {

    home.sessionVariables = lib.mkIf osConfig.arcworks.desktop.wallet.kwallet.enable {
      SSH_ASKPASS = "ksshaskpass";
      SSH_ASKPASS_REQUIRE = "prefer";
    };

    home.packages = with pkgs; [
      nixd
      nixfmt-rfc-style
      tlrc
      nix-tree
    ];

    programs.firefox.enable = true; # TODO: move custom config for tab bar and stuff into here

    # use services.tailscale.extraSetFlags = [ "--operator=arc" ]; at nixos level
    # to enable full functionality
    # we aren't hard coding it because the intended user may not be arc
    # https://tailscale.com/kb/1023/troubleshooting#operator-permission
    services.tailscale-systray.enable = osConfig.arcworks.network.tailnet.enable;
  };
}
