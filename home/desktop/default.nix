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

    home.sessionVariables = {
      SSH_ASKPASS = lib.mkIf osConfig.arcworks.desktop.wallet.kwallet.enable "ksshaskpass";
      SSH_ASKPASS_REQUIRE = "prefer";
    };

    home.packages = with pkgs; [
      nixd
      nixfmt-rfc-style
      tlrc
      nix-tree
    ];

    programs.firefox.enable = true; # TODO: move custom config for tab bar and stuff into here
  };
}
