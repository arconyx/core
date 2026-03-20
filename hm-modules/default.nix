{
  ...
}:
{
  imports = [
    ./helix.nix
    ./jujutsu/jujutsu.nix
    ./terminal.nix
  ];

  # cleanup old profiles automatically
  nix.gc = {
    automatic = true;
    dates = "weekly";
    persistent = true;
    options = "--delete-older-than 14d"; # TODO: sync everything with system nix-gc?
    # add a little jitter so we don't run at the same time
    # as all the other weekly persistent timers
    randomizedDelaySec = "45min";
  };

  xdg = {
    enable = true;
    userDirs.enable = true;
  };
}
