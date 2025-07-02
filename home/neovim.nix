{
  lib,
  pkgs,
  osConfig,
  config,
  ...
}:
{
  options.arcworks.neovim.enable = lib.mkEnableOption "neovim";

  config = lib.mkIf config.arcworks.neovim.enable {
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      vimAlias = true;
      extraConfig = ''
        set number
        set expandtab 
        set shiftwidth=4 smarttab
        set tabstop=4 softtabstop=-1
      '';

      # be minimal on pis
      withRuby = !(osConfig.arcworks.server.pi);
      withPython3 = !(osConfig.arcworks.server.pi);

      plugins =
        with pkgs.vimPlugins;
        [
          {
            plugin = monokai-pro-nvim;
            config = "colorscheme monokai-pro";
          }
          {
            plugin = comment-nvim;
            type = "lua";
            config = ''
              require'Comment'.setup{}
            '';
          }
        ]
        ++ lib.optionals (!osConfig.arcworks.server.pi) [
          {
            plugin = nvim-treesitter.withAllGrammars;
            type = "lua";
            config = builtins.readFile ./dotfiles/treesitter.lua;
          }
          {
            plugin = nvim-lspconfig;
            type = "lua";
            config = ''
              require'lspconfig'.nixd.setup{}
            '';
          }
        ];
    };
  };
}
