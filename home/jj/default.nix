{
  lib,
  config,
  ...
}:
{
  options.arcworks.jujutsu.enable = lib.mkEnableOption "Enable jujutsu and related configuration";

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
