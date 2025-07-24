{
  config,
  lib,
  pkgs,
  ...
}:
{
  # TODO: Maybe this should be nested under server.pi?
  options.arcworks.server.minimal.enable = lib.mkEnableOption "stripped down config for pis";

  config = lib.mkIf config.arcworks.server.minimal.enable {
    assertions = [
      {
        assertion = (!config.arcworks.server.minimal.enable) || config.arcworks.server.pi;
        message = "Minimal module designed around pis and needs manual verification before application to another system";
      }
    ];

    # strip down the system
    # based on the nixpkgs minimal profile for nixos until marked otherwise
    documentation = {
      enable = true;
      doc.enable = false;
      info.enable = false; # also part of perlless
      nixos.includeAllModules = lib.mkForce false; # rebuilds on every change and we don't need it that badly on a server
    };
    environment.defaultPackages = [ ];
    environment.systemPackages = [
      pkgs.strace
    ]; # normally part of default packages, too useful to exclude

    # don't care about any of this
    boot.enableContainers = false;
    programs.command-not-found.enable = false;
    services.udisks2.enable = false;

    # desktop stuff we don't care about on a headless machine
    xdg = {
      autostart.enable = false;
      icons.enable = false;
      mime.enable = false;
      sounds.enable = false;
    };

    # perl stuff from perlless profile
    # currently disabled because system.etc.overlay has an experimental warning on it, so we need to stick with the perl version
    # remove perl from activation

    # boot.initrd.systemd.enable = true;

    # system.etc.overlay DOES NOT MIGRATE ON SWITCH, WIPING OUT /etc/shadow
    # and thus user login!!!
    # system.etc.overlay.enable = true;

    # services.userborn.enable = true;
    # programs.less.lessopen = null;
    system.tools.nixos-generate-config.enable = lib.mkDefault false;

    # stuff from headless profile
    # Don't start a tty on the serial consoles.
    systemd.services = {
      "serial-getty@ttyS0".enable = false;
      "serial-getty@hvc0".enable = false;
      "getty@tty1".enable = false;
      "autovt@".enable = false;
    };

    # Since we can't manually respond to a panic, just reboot.
    boot.kernelParams = [
      "panic=1"
      "boot.panic_on_fail"
      # "vga=0x317" not sure this would achieve much
      "nomodeset"
    ];

    # Don't allow emergency mode, because we don't have a console.
    systemd.enableEmergencyMode = false;

  };
}
