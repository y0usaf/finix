###############################################################################
# Enhanced Neovim Configuration (Lua + vim-jetpack)
# Modern, enjoyable Neovim setup with premium developer experience
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.dev.nvim;
  inherit (config.shared) username;
  
  # Lua configuration using lib.generators.toLua
  neovimConfig = {
    # Global variables
    globals = {
      mapleader = " ";
      maplocalleader = "\\";
      loaded_netrw = 1;
      loaded_netrwPlugin = 1;
      loaded_matchparen = 1;
    };
    
    # Vim options
    options = {
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
      completeopt = "menu,menuone,noselect";
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
    
    # Keymaps
    keymaps = [
      { mode = "i"; key = "jk"; action = "<Esc>"; desc = "Exit insert mode"; }
      { mode = "n"; key = "<C-h>"; action = "<C-w>h"; desc = "Move to left window"; }
      { mode = "n"; key = "<C-j>"; action = "<C-w>j"; desc = "Move to bottom window"; }
      { mode = "n"; key = "<C-k>"; action = "<C-w>k"; desc = "Move to top window"; }
      { mode = "n"; key = "<C-l>"; action = "<C-w>l"; desc = "Move to right window"; }
      { mode = "n"; key = "<leader>e"; action = ":Neotree toggle<CR>"; desc = "Toggle file explorer"; }
      { mode = "n"; key = "<leader>ff"; action = ":Telescope find_files<CR>"; desc = "Find files"; }
      { mode = "n"; key = "<leader>fw"; action = ":Telescope live_grep<CR>"; desc = "Find word"; }
      { mode = "n"; key = "<leader>fb"; action = ":Telescope buffers<CR>"; desc = "Find buffers"; }
      { mode = "n"; key = "gd"; action = ":Telescope lsp_definitions<CR>"; desc = "Go to definition"; }
      { mode = "n"; key = "gr"; action = ":Telescope lsp_references<CR>"; desc = "Go to references"; }
      { mode = "n"; key = "K"; action = "<cmd>lua vim.lsp.buf.hover()<CR>"; desc = "Hover documentation"; }
      { mode = "n"; key = "<leader>ca"; action = "<cmd>lua vim.lsp.buf.code_action()<CR>"; desc = "Code actions"; }
    ];
    
    # vim-jetpack plugins
    plugins = [
      "tani/vim-jetpack"
      "nvim-tree/nvim-web-devicons"
      "neovim/nvim-lspconfig"
      "hrsh7th/nvim-cmp"
      "hrsh7th/cmp-nvim-lsp"
      "hrsh7th/cmp-buffer"
      "hrsh7th/cmp-path"
      "L3MON4D3/LuaSnip"
      "saadparwaiz1/cmp_luasnip"
      "nvim-neo-tree/neo-tree.nvim"
      "nvim-lua/plenary.nvim"
      "MunifTanjim/nui.nvim"
      "nvim-telescope/telescope.nvim"
      "nvim-telescope/telescope-fzf-native.nvim"
      "nvim-treesitter/nvim-treesitter"
      "nvim-lualine/lualine.nvim"
      "lewis6991/gitsigns.nvim"
      "folke/which-key.nvim"
      "windwp/nvim-autopairs"
      "numToStr/Comment.nvim"
      "kdheepak/lazygit.nvim"
      "stevearc/conform.nvim"
    ];
  };
  
  # Generate init.lua content
  initLua = pkgs.writeText "init.lua" ''
    -- Bootstrap vim-jetpack
    local fn = vim.fn
    local jetpack_path = fn.stdpath('data') .. '/site/pack/jetpack/opt/vim-jetpack'
    if fn.empty(fn.glob(jetpack_path)) > 0 then
      fn.system({
        'git', 'clone', '--depth', '1',
        'https://github.com/tani/vim-jetpack.git',
        jetpack_path
      })
    end
    vim.cmd('packadd vim-jetpack')
    
    -- Set globals
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "vim.g.${k} = ${lib.generators.toLua {} v}") neovimConfig.globals)}
    
    -- Set options
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "vim.opt.${k} = ${lib.generators.toLua {} v}") neovimConfig.options)}
    
    -- Plugin setup
    require('jetpack').startup(function(use)
      ${lib.concatStringsSep "\n" (map (plugin: "  use '${plugin}'") neovimConfig.plugins)}
    end)
    
    -- Keymaps
    ${lib.concatStringsSep "\n" (map (keymap: 
      "vim.keymap.set('${keymap.mode}', '${keymap.key}', '${keymap.action}', { desc = '${keymap.desc}' })"
    ) neovimConfig.keymaps)}
    
    -- LSP Configuration
    local lspconfig = require('lspconfig')
    local capabilities = require('cmp_nvim_lsp').default_capabilities()
    
    lspconfig.lua_ls.setup { capabilities = capabilities }
    lspconfig.nil_ls.setup { capabilities = capabilities }
    lspconfig.pyright.setup { capabilities = capabilities }
    lspconfig.rust_analyzer.setup { capabilities = capabilities }
    lspconfig.ts_ls.setup { capabilities = capabilities }
    lspconfig.html.setup { capabilities = capabilities }
    lspconfig.cssls.setup { capabilities = capabilities }
    lspconfig.jsonls.setup { capabilities = capabilities }
    lspconfig.bashls.setup { capabilities = capabilities }
    lspconfig.marksman.setup { capabilities = capabilities }
    
    -- CMP Configuration
    local cmp = require('cmp')
    cmp.setup({
      snippet = {
        expand = function(args)
          require('luasnip').lsp_expand(args.body)
        end,
      },
      sources = cmp.config.sources({
        { name = 'nvim_lsp', priority = 1000 },
        { name = 'luasnip', priority = 750 },
        { name = 'buffer', priority = 500 },
        { name = 'path', priority = 250 },
      }),
      mapping = cmp.mapping.preset.insert({
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.abort(),
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
        ['<Tab>'] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          elseif require('luasnip').expand_or_jumpable() then
            require('luasnip').expand_or_jump()
          else
            fallback()
          end
        end, {'i', 's'}),
        ['<S-Tab>'] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif require('luasnip').jumpable(-1) then
            require('luasnip').jump(-1)
          else
            fallback()
          end
        end, {'i', 's'}),
      }),
      window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
      },
      experimental = {
        ghost_text = true,
      },
    })
    
    -- Neo-tree Configuration
    require('neo-tree').setup({
      close_if_last_window = true,
      enable_git_status = true,
      window = {
        width = 35,
      },
    })
    
    -- Telescope Configuration
    require('telescope').setup({
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
        }
      }
    })
    require('telescope').load_extension('fzf')
    
    -- Treesitter Configuration
    require('nvim-treesitter.configs').setup({
      ensure_installed = {
        "lua", "nix", "python", "rust", "typescript", "javascript",
        "html", "css", "json", "yaml", "bash", "markdown"
      },
      highlight = {
        enable = true,
      },
      indent = {
        enable = true,
      },
    })
    
    -- Lualine Configuration
    require('lualine').setup({
      options = {
        theme = 'auto'
      }
    })
    
    -- Other plugin configurations
    require('gitsigns').setup()
    require('which-key').setup()
    require('nvim-autopairs').setup()
    require('Comment').setup()
    
    -- Conform Configuration
    require('conform').setup({
      formatters_by_ft = {
        lua = { "stylua" },
        nix = { "alejandra" },
        python = { "black" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        rust = { "rustfmt" },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
    })
    
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
  
  # Custom Neovim package with Lua configuration
  customNeovim = pkgs.neovim.override {
    configure = {
      customRC = "luafile ${initLua}";
    };
  };
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.dev.nvim = {
    enable = lib.mkEnableOption "Enhanced NixVim editor with modern features";
    neovide = lib.mkEnableOption "Neovide GUI for Neovim";
  };

  ###########################################################################
  # Module Configuration - nix-maid packages
  ###########################################################################
  config = lib.mkIf cfg.enable {
    users.users.${username}.maid = {
      packages = with pkgs; [
        # Enhanced terminal tools for Neovim workflow
        lazygit
        ripgrep
        fd
        tree-sitter
        
        # Custom Neovim with Lua configuration
        customNeovim
      ] ++ lib.optionals cfg.neovide [
        neovide
      ];
    };
  };
}