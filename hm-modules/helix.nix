{
  lib,
  config,
  osConfig,
  ...
}:
{
  options.arcworks.helix.enable = lib.mkEnableOption "helix";

  config = lib.mkIf config.arcworks.helix.enable {
    programs.helix = {
      enable = true;
      defaultEditor = true;
      settings = {
        theme = "monokai_soda";
        editor = {
          line-number = "relative";
        };
      };
      languages = {
        language = [
          {
            name = "nix";
            auto-format = true;
          }
        ];
        language-server.nixd = {
          command = "nixd";
          # Should we point this directly at /etc/nixos instead of ./.?
          # See https://github.com/helix-editor/helix/discussions/8474#discussioncomment-12999403
          # and https://github.com/nix-community/nixd/blob/main/nixd/docs/configuration.md
          # TODO: Hardcoded /config/nixos not very portable
          formatting = {
            command = [ "nixfmt" ];
          }
          # using the desktop as a bad proxy for if /config exists
          // lib.optionalAttrs (!osConfig.arcworks.desktop.enable) {
            nixpkgs.expr = "import (builtins.getFlake \"/config\").inputs.nixpkgs { }";
            options.nixos.expr = "(builtins.getFlake \"/config\").nixosConfigurations.${osConfig.networking.hostName}.options";
            options.home-manager.expr = "(builtins.getFlake \"/config\").nixosConfigurations.${osConfig.networking.hostName}.options.home-manager.users.type.getSubOptions []";
          };
        };
      };
    };
  };
}
