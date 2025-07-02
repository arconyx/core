{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.arcworks.desktop.wallet = {
    kwallet.enable = lib.mkEnableOption "kwallet";
  };

  config =
    let
      cfg = config.arcworks.desktop.wallet;
    in
    lib.mkIf cfg.kwallet.enable {
      security.pam.services.login.kwallet = {
        enable = true;
        package = pkgs.kdePackages.kwallet-pam;
      }; # this should add rules to /etc/pam.d/sddm but it doesn't

      environment.systemPackages = with pkgs.kdePackages; [
        qtwayland
        kservice
        kwallet
        kwallet-pam
        breeze
        breeze-icons
        qtsvg
        ksshaskpass
      ];
    };
}
