# Modified from https://github.com/femtodata/nix-utils/blob/581506053fcce4c0e1f679be65395cbdd8389516/modules/switch-fix.nix
# See also https://blog.femtodata.com/posts/switch-fix/

{
  pkgs,
  config,
  lib,
  ...
}:
let
  rollback-profile-path = "/var/lib/nix-autorollback/profile";
  rollback-delay = "600";
  set-rollback = pkgs.writeShellScriptBin "set-rollback" ''
    sudo mkdir -p $(dirname ${rollback-profile-path})
    sudo ln -sf $(readlink /run/current-system) ${rollback-profile-path}
  '';
  cancel-rollback = pkgs.writeShellScriptBin "cancel-rollback" ''
    sudo systemctl stop nix-autorollback.service
    sudo rm ${rollback-profile-path}
  '';
in
{
  config = lib.mkIf config.arcworks.server.enable {
    environment.systemPackages = [
      set-rollback
      cancel-rollback
    ];

    systemd.services."nix-autorollback" = {
      description = "rollback to set profile unless stopped";
      wantedBy = [ "sysinit.target" ];
      script = ''
        if [ -d ${rollback-profile-path} ]; then
          ${pkgs.util-linux}/bin/wall -t 5 "Autorollback in ${rollback-delay}"
          echo "Autorollback in ${rollback-delay}"
          ${pkgs.coreutils}/bin/sleep ${rollback-delay}
          ${pkgs.util-linux}/bin/wall "Rolling back to $(readlink ${rollback-profile-path})"
          echo "Rolling back to $(readlink ${rollback-profile-path})"
          ${pkgs.nix}/bin/nix-env --profile /nix/var/nix/profiles/system --set $(readlink ${rollback-profile-path})
          $(readlink ${rollback-profile-path})/bin/switch-to-configuration boot
          rm ${rollback-profile-path}
          ${pkgs.systemd}/bin/shutdown -r now
        fi
      '';
      serviceConfig = {
        Type = "simple";
        User = "root";
      };
    };
  };
}
