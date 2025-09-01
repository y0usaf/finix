{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.dev.nvim;
  opencodeCfg = config.home.dev.opencode;
  username = config.user.name;
in {
  imports = [
    ./neovide.nix
    ./options.nix
    ./packages.nix
  ];

  config = lib.mkIf cfg.enable {
    hjem.users.${username}.files = {
      # Core nvim configuration generated from Nix
      ".config/nvim/init.lua" = {
        generator = lib.generators.toLua {asBindings = true;};
        value = {
          # Leader keys
          "vim.g.mapleader" = " ";
          "vim.g.maplocalleader" = "\\";

          # Line numbers and UI
          "vim.opt.number" = true;
          "vim.opt.relativenumber" = true;
          "vim.opt.signcolumn" = "yes";
          "vim.opt.wrap" = true;
          "vim.opt.linebreak" = true;
          "vim.opt.breakindent" = true;
          "vim.opt.showbreak" = "↪ ";
          "vim.opt.termguicolors" = true;
          "vim.opt.scrolloff" = 8;
          "vim.opt.sidescrolloff" = 8;
          "vim.opt.cursorline" = true;
          "vim.opt.pumheight" = 15;
          "vim.opt.showmode" = false;
          "vim.opt.laststatus" = 2;
          "vim.opt.cmdheight" = 1;

          # Indentation
          "vim.opt.expandtab" = true;
          "vim.opt.tabstop" = 2;
          "vim.opt.shiftwidth" = 2;

          # System integration
          "vim.opt.clipboard" = "unnamedplus";
          "vim.opt.mouse" = "a";

          # Search
          "vim.opt.ignorecase" = true;
          "vim.opt.smartcase" = true;

          # Timing
          "vim.opt.updatetime" = 250;
          "vim.opt.timeoutlen" = 300;

          # Splits
          "vim.opt.splitbelow" = true;
          "vim.opt.splitright" = true;
          "vim.opt.splitkeep" = "screen";
          "vim.opt.virtualedit" = "onemore";
        };
      };
      ".config/nvim/lua/vim-pack-config.lua".source = ./config/lua/vim-pack-config.lua;

      # Conditional opencode files - only if opencode is enabled
      ".config/nvim/lua/vim-pack-opencode.lua" = lib.mkIf opencodeCfg.enable {
        source = ./config/lua/vim-pack-opencode.lua;
      };
      ".config/nvim/lua/opencode-config.lua" = lib.mkIf opencodeCfg.enable {
        source = ./config/lua/opencode-config.lua;
      };
    };
  };
}
