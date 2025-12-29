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
          name = config.programs.git.settings.user.name;
          email = config.programs.git.settings.user.email;
        };
        aliases.tug = [
          "bookmark"
          "move"
          "--from"
          "closest_bookmark(@-)"
          "--to"
          "@-"
        ];
        revset-aliases."closest_bookmark(to)" = "heads(::to & bookmarks())";
        templates.log = "log_oneline";
        template-aliases = {
          log_oneline = "log_oneline(self)";
          "log_oneline(commit)" = ''
            if(
              commit.root(),
              format_root_commit(commit),
              label(
                separate(" ",
                  if(commit.current_working_copy(), "working_copy"),
                  if(commit.immutable(), "immutable", "mutable"),
                  if(commit.conflict(), "conflicted")
                ),
                concat(
                  separate(" ",
                    format_short_change_id_with_hidden_and_divergent_info(commit),
                    if(!commit.mine(), format_short_signature_oneline(commit.author())),
                    truncate_end(5, commit_timestamp(commit).ago()),
                    commit.bookmarks(),
                    commit.tags(),
                    commit.working_copies(),
                    if(commit.git_head(), label("git_head", "git_head()")),
                    
                    if(commit.conflict(), label("conflict", "conflict")),
                    if(config("ui.show-cryptographic-signatures").as_boolean(),
                      format_short_cryptographic_signature(commit.signature())),
                    if(commit.empty(), label("empty", "(empty)")),
                    if(commit.description(),
                      commit.description().first_line(),
                      label(if(commit.empty(), "empty"), description_placeholder),
                    ),
                    if(commit.description().lines().len() > 1,
                      "◀"
                    ),
                  ) ++ "\n",
                ),
              )
            )
          '';
        };
        git.private-commits = "description(glob:'wip:*') | description(glob:'private:*') | description(glob:'broken:*')";
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
