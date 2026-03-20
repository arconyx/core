# Configuration for terminal environment
# As I prefer it
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.arcworks.terminal;
in
{
  options.arcworks.terminal = {
    enable = lib.mkEnableOption "personal terminal config";
    minimal = lib.mkEnableOption "remove some utils";
  };

  config = lib.mkIf cfg.enable {
    arcworks.helix.enable = true;

    home.packages = with pkgs; [
      # archives
      _7zz
      zip
      unzip

      # disk
      dysk
      dust
    ];

    programs = {
      bash = {
        enable = true;
        enableCompletion = true;
        historyControl = [ "ignoreboth" ];
      };

      bat = {
        enable = true;
        extraPackages = with pkgs.bat-extras; [
          batman
        ];
      };

      delta = {
        enable = !cfg.minimal;
        enableGitIntegration = true;
        options.navigate = true;
      };

      direnv = {
        enable = !cfg.minimal;
        nix-direnv.enable = true;
      };

      eza = {
        enable = true;
        icons = "auto";
      };

      fd.enable = true;

      fish = {
        enable = true;
        interactiveShellInit = ''
          fish_vi_key_bindings
          bind / fzf-history-widget
          batman --export-env | source
        '';
        # trying out abbrs for once
        shellAbbrs = {
          # download silently, but fail and print error if we get an http error
          download = "curl -sSfLO --no-clobber";
          # curl with headers
          # curlie was too weird around autocomplete and manual
          curlie = "curl -D -";
        };
      };

      fzf = {
        enable = true;
        defaultCommand = "fd --type f --strip-cwd-prefix";
      };

      git = {
        enable = true;
        ignores = [
          ".direnv/"
          ".envrc"
        ];
        settings = {
          safe.directory = "/config/*";
          init.defaultBranch = "main";
          merge.conflictstyle = "zdiff3";
          pull.ff = "only";
        };
        package = if cfg.minimal then pkgs.gitMinimal else pkgs.git;
      };

      nh = {
        enable = true;
        flake = "/config";
      };

      ripgrep = {
        enable = true;
        arguments = [
          "--smart-case"
          "--follow"
        ];
      };

      ssh = {
        enable = true;
        matchBlocks."*" = {
          hashKnownHosts = true;
          addKeysToAgent = "yes";
        };
        enableDefaultConfig = false;
      };
    };

    services.ssh-agent.enable = !cfg.minimal;
  };
}
