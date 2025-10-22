{
  pkgs,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    ./../../core.nix
    "${modulesPath}/installer/cd-dvd/installation-cd-graphical-calamares.nix"
  ];

  arcworks.desktop.enable = true;

  documentation = {
    doc.enable = true;
    info.enable = true;
    man.enable = true;
    nixos.enable = true;
    nixos.includeAllModules = true;
  };

  home-manager.users.arc = {
    home.file."Pictures/wallpaper.jpg".source = ./assets/alena-aenami-lights-1k.jpg;
    programs.git = {
      userName = "ArcOnyx";
      userEmail = "11323309+arconyx@users.noreply.github.com";
    };
  };

  services.displayManager.sddm.sugarCandyNix.settings.Background =
    lib.cleanSource ./assets/alena-aenami-lights-1k.jpg;

  # Default profile setups a nixos user, which we're leaving enabled
  # but not using, in favour of arc.

  # Allow the user to log in as arc without a password.
  users.users.arc.initialHashedPassword = "";

  # Automatically log in at the virtual consoles.
  services.displayManager.autoLogin = {
    enable = true;
    user = "arc";
  };

  # Override tailnet disabling ssh
  services.openssh.enable = lib.mkForce true;

  arcworks.network.tailnet.enable = true;

  isoImage.edition = "arcworks";

  environment.systemPackages = with pkgs; [
    disko
    nixos-anywhere
    restic
  ];

  nixpkgs.hostPlatform.system = "x86_64-linux";
}
