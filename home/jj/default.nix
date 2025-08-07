{
  lib,
  config,
  osConfig,
  ...
}:
{
  options.arcworks.jujutsu.enable = lib.mkOption {
    type = lib.types.bool;
    # Should probably change this when I drag it into core
    # Just enable it in the default user config
    default = osConfig.arcworks.desktop.enable;
    example = true;
    description = "Enable jujutsu and related configuration";
  };

  config = lib.mkIf config.arcworks.jujutsu.enable {
    programs.jujutsu = {
      enable = true;
      settings = {
        user = {
          name = config.programs.git.userName;
          email = config.programs.git.userEmail;
        };
      };
    };

    programs.fish.functions = {
      fish_jj_prompt = {
        body = builtins.readFile ./fish_jj_prompt.fish;
        description = "Write out the jj prompt";
      };
      fish_vcs_prompt = {
        body = builtins.readFile ./fish_vcs_prompt.fish;
        description = "Print all vcs prompts";
      };
    };
  };
}
