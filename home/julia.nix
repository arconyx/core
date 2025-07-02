{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.arcworks.julia.enable = lib.mkEnableOption "Julia";

  config = lib.mkIf config.arcworks.julia.enable {
    home.packages = [ pkgs.julia ];
    programs.neovim = lib.mkIf config.arcworks.neovim.enable {
      plugins = with pkgs.vimPlugins; [
        julia-vim
      ];
      extraLuaConfig = ''
        require'lspconfig'.julials.setup{}
      '';
    };
    # for nvim lsp
    home.file.".julia/environments/nvim-lspconfig" = lib.mkIf config.arcworks.neovim.enable {
      source = ./dotfiles/julia-environments/nvim-lspconfig;
      recursive = true;
    };
  };
}
