# Configuration for terminal environment
# As I prefer it
{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  minimal = osConfig.arcworks.server.minimal.enable;
in
{
  options.arcworks.terminal.enable = "personal terminal config";

  config = lib.mkIf config.arcworks.terminal.enable {
    arcworks.helix.enable = true;

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
        enable = !minimal;
        enableGitIntegration = true;
        options.navigate = true;
      };

      direnv = {
        enable = !minimal;
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
        package = if minimal then pkgs.gitMinimal else pkgs.git;
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

    services.ssh-agent.enable = !minimal;
  };
}
