###############################################################################
# Enhanced Neovim Configuration (NixVim)
# Modern, enjoyable Neovim setup with premium developer experience
###############################################################################
{
  config,
  lib,
  pkgs,
  nixvim,
  ...
}: let
  cfg = config.home.dev.nvim;
  inherit (config.shared) username;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.dev.nvim = {
    enable = lib.mkEnableOption "Enhanced NixVim editor with modern features";
    neovide = lib.mkEnableOption "Neovide GUI for Neovim";
  };

  ###########################################################################
  # Module Configuration - User packages via nix-maid
  ###########################################################################
  config = lib.mkIf cfg.enable {
    users.users.${username}.maid = {
      packages = with pkgs; [
        # Enhanced terminal tools for Neovim workflow
        lazygit
        ripgrep
        fd
        tree-sitter
        
        # NixVim with full configuration as user package
        (nixvim.legacyPackages.${pkgs.system}.makeNixvimWithModule {
          inherit pkgs;
          module = {
            
            globals = {
              mapleader = " ";
              maplocalleader = "\\";
              loaded_netrw = 1;
              loaded_netrwPlugin = 1;
              loaded_matchparen = 1;
            };
            
            opts = {
              clipboard = "unnamedplus";
              mouse = "a";
              number = true;
              relativenumber = true;
              expandtab = true;
              tabstop = 2;
              shiftwidth = 2;
              softtabstop = 2;
              autoindent = true;
              smartindent = true;
              wrap = false;
              termguicolors = true;
              background = "dark";
              conceallevel = 2;
              ignorecase = true;
              smartcase = true;
              hlsearch = true;
              incsearch = true;
              grepprg = "rg --vimgrep";
              signcolumn = "yes:2";
              updatetime = 250;
              timeoutlen = 300;
              cmdheight = 0;
              laststatus = 3;
              showtabline = 2;
              pumheight = 10;
              pumblend = 10;
              winblend = 10;
              completeopt = ["menu" "menuone" "noselect"];
              backup = false;
              writebackup = false;
              swapfile = false;
              undofile = true;
              undolevels = 10000;
              splitright = true;
              splitbelow = true;
              scrolloff = 8;
              sidescrolloff = 8;
              lazyredraw = true;
              synmaxcol = 240;
              cursorline = true;
              showmode = false;
              list = true;
              listchars = "tab:→ ,eol:↲,nbsp:␣,trail:•,extends:⟩,precedes:⟨";
              fillchars = "eob: ,fold: ,foldopen:▾,foldsep: ,foldclose:▸";
            };

            keymaps = [
              { mode = "i"; key = "jk"; action = "<Esc>"; options.desc = "Exit insert mode"; }
              { mode = "n"; key = "<C-h>"; action = "<C-w>h"; options.desc = "Move to left window"; }
              { mode = "n"; key = "<C-j>"; action = "<C-w>j"; options.desc = "Move to bottom window"; }
              { mode = "n"; key = "<C-k>"; action = "<C-w>k"; options.desc = "Move to top window"; }
              { mode = "n"; key = "<C-l>"; action = "<C-w>l"; options.desc = "Move to right window"; }
              { mode = "n"; key = "<leader>e"; action = ":Neotree toggle<CR>"; options.desc = "Toggle file explorer"; }
              { mode = "n"; key = "<leader>ff"; action = ":Telescope find_files<CR>"; options.desc = "Find files"; }
              { mode = "n"; key = "<leader>fw"; action = ":Telescope live_grep<CR>"; options.desc = "Find word"; }
              { mode = "n"; key = "<leader>fb"; action = ":Telescope buffers<CR>"; options.desc = "Find buffers"; }
              { mode = "n"; key = "gd"; action = ":Telescope lsp_definitions<CR>"; options.desc = "Go to definition"; }
              { mode = "n"; key = "gr"; action = ":Telescope lsp_references<CR>"; options.desc = "Go to references"; }
              { mode = "n"; key = "K"; action = "<cmd>lua vim.lsp.buf.hover()<CR>"; options.desc = "Hover documentation"; }
              { mode = "n"; key = "<leader>ca"; action = "<cmd>lua vim.lsp.buf.code_action()<CR>"; options.desc = "Code actions"; }
            ];

            plugins = {
              web-devicons.enable = true;
              
              lsp = {
                enable = true;
                servers = {
                  lua_ls.enable = true;
                  nil_ls.enable = true;
                  pyright.enable = true;
                  rust_analyzer = {
                    enable = true;
                    installRustc = true;
                    installCargo = true;
                  };
                  ts_ls.enable = true;
                  html.enable = true;
                  cssls.enable = true;
                  jsonls.enable = true;
                  bashls.enable = true;
                  marksman.enable = true;
                };
              };
              
              cmp = {
                enable = true;
                settings = {
                  snippet.expand = "function(args) require('luasnip').lsp_expand(args.body) end";
                  sources = [
                    { name = "nvim_lsp"; priority = 1000; }
                    { name = "luasnip"; priority = 750; }
                    { name = "buffer"; priority = 500; }
                    { name = "path"; priority = 250; }
                  ];
                  mapping = {
                    "<C-Space>" = "cmp.mapping.complete()";
                    "<C-e>" = "cmp.mapping.abort()";
                    "<CR>" = "cmp.mapping.confirm({ select = true })";
                    "<Tab>" = "cmp.mapping(function(fallback) if cmp.visible() then cmp.select_next_item() elseif require('luasnip').expand_or_jumpable() then require('luasnip').expand_or_jump() else fallback() end end, {'i', 's'})";
                    "<S-Tab>" = "cmp.mapping(function(fallback) if cmp.visible() then cmp.select_prev_item() elseif require('luasnip').jumpable(-1) then require('luasnip').jump(-1) else fallback() end end, {'i', 's'})";
                  };
                  window = {
                    completion.border = "rounded";
                    documentation.border = "rounded";
                  };
                  experimental.ghost_text = true;
                };
              };
              
              luasnip.enable = true;
              
              neo-tree = {
                enable = true;
                closeIfLastWindow = true;
                enableGitStatus = true;
                window.width = 35;
              };
              
              telescope = {
                enable = true;
                extensions.fzf-native.enable = true;
              };
              
              treesitter = {
                enable = true;
                settings = {
                  highlight.enable = true;
                  indent.enable = true;
                  ensure_installed = [
                    "lua" "nix" "python" "rust" "typescript" "javascript"
                    "html" "css" "json" "yaml" "bash" "markdown"
                  ];
                };
              };
              
              lualine = {
                enable = true;
                settings.options.theme = "auto";
              };
              
              gitsigns.enable = true;
              which-key.enable = true;
              nvim-autopairs.enable = true;
              comment.enable = true;
              lazygit.enable = true;
              
              conform-nvim = {
                enable = true;
                settings = {
                  formatters_by_ft = {
                    lua = ["stylua"];
                    nix = ["alejandra"];
                    python = ["black"];
                    javascript = ["prettier"];
                    typescript = ["prettier"];
                    rust = ["rustfmt"];
                  };
                  format_on_save = {
                    timeout_ms = 500;
                    lsp_fallback = true;
                  };
                };
              };
            };

            extraConfigLua = ''
              -- Enhanced diagnostics
              vim.diagnostic.config({
                virtual_text = { enabled = true, prefix = "●" },
                signs = true,
                underline = true,
                severity_sort = true,
                float = { border = "rounded" },
              })
              
              -- LSP UI
              local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
              for type, icon in pairs(signs) do
                local hl = "DiagnosticSign" .. type
                vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
              end
              
              -- Transparency
              vim.cmd([[
                highlight Normal guibg=NONE ctermbg=NONE
                highlight NonText guibg=NONE ctermbg=NONE
                highlight SignColumn guibg=NONE ctermbg=NONE
                highlight EndOfBuffer guibg=NONE ctermbg=NONE
              ]])
            '';
          };
        })
      ] ++ lib.optionals cfg.neovide [
        neovide
      ];
    };
  };
}