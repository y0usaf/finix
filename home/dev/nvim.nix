###############################################################################
# Enhanced Neovim Configuration (Pure Nix + Embedded Lua)
# Modern, reproducible Neovim setup with LSP and productivity tools
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.dev.nvim;
  inherit (config.shared) username;
  
  # Neovim plugins from nixpkgs
  neovimPlugins = with pkgs.vimPlugins; [
    # Core functionality
    nvim-web-devicons
    plenary-nvim
    
    # LSP and completion
    nvim-lspconfig
    nvim-cmp
    cmp-nvim-lsp
    cmp-buffer
    cmp-path
    luasnip
    cmp_luasnip
    
    # File navigation
    neo-tree-nvim
    nui-nvim
    telescope-nvim
    telescope-fzf-native-nvim
    
    # Syntax and editing
    (nvim-treesitter.withPlugins (p: with p; [
      lua nix python rust typescript javascript
      html css json yaml bash markdown
    ]))
    
    # UI and statusline
    lualine-nvim
    which-key-nvim
    
    # Git integration
    gitsigns-nvim
    lazygit-nvim
    
    # Editing enhancements
    nvim-autopairs
    comment-nvim
    
    # Formatting
    conform-nvim
  ];
  
  # LSP servers and tools
  lspPackages = with pkgs; [
    # Language servers
    lua-language-server
    nil # Nix LSP
    pyright
    rust-analyzer
    typescript-language-server
    vscode-langservers-extracted # html, css, json
    bash-language-server
    marksman # Markdown LSP
    
    # Formatters
    stylua
    alejandra
    black
    prettier
    rustfmt
  ];
  
  # Neovim configuration structure
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
      undofile = true;
      undolevels = 10000;
      backup = false;
      writebackup = false;
      swapfile = false;
      number = true;
      relativenumber = true;
      signcolumn = "yes:2";
      cursorline = true;
      termguicolors = true;
      background = "dark";
      conceallevel = 2;
      showmode = false;
      laststatus = 3;
      showtabline = 2;
      cmdheight = 0;
      pumheight = 10;
      pumblend = 10;
      winblend = 10;
      expandtab = true;
      tabstop = 2;
      shiftwidth = 2;
      softtabstop = 2;
      autoindent = true;
      smartindent = true;
      wrap = false;
      ignorecase = true;
      smartcase = true;
      hlsearch = true;
      incsearch = true;
      grepprg = "rg --vimgrep";
      updatetime = 250;
      timeoutlen = 300;
      lazyredraw = true;
      synmaxcol = 240;
      splitright = true;
      splitbelow = true;
      scrolloff = 8;
      sidescrolloff = 8;
      completeopt = "menu,menuone,noselect";
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
      { mode = "n"; key = "<C-Up>"; action = ":resize -2<CR>"; desc = "Resize window up"; }
      { mode = "n"; key = "<C-Down>"; action = ":resize +2<CR>"; desc = "Resize window down"; }
      { mode = "n"; key = "<C-Left>"; action = ":vertical resize -2<CR>"; desc = "Resize window left"; }
      { mode = "n"; key = "<C-Right>"; action = ":vertical resize +2<CR>"; desc = "Resize window right"; }
      { mode = "n"; key = "<S-l>"; action = ":bnext<CR>"; desc = "Next buffer"; }
      { mode = "n"; key = "<S-h>"; action = ":bprevious<CR>"; desc = "Previous buffer"; }
      { mode = "n"; key = "<leader>bd"; action = ":bdelete<CR>"; desc = "Delete buffer"; }
      { mode = "n"; key = "<leader>e"; action = ":Neotree toggle<CR>"; desc = "Toggle file explorer"; }
      { mode = "n"; key = "<leader>ff"; action = ":Telescope find_files<CR>"; desc = "Find files"; }
      { mode = "n"; key = "<leader>fw"; action = ":Telescope live_grep<CR>"; desc = "Find word"; }
      { mode = "n"; key = "<leader>fb"; action = ":Telescope buffers<CR>"; desc = "Find buffers"; }
      { mode = "n"; key = "<leader>fh"; action = ":Telescope help_tags<CR>"; desc = "Find help"; }
      { mode = "n"; key = "<leader>fr"; action = ":Telescope oldfiles<CR>"; desc = "Find recent files"; }
      { mode = "n"; key = "gd"; action = ":Telescope lsp_definitions<CR>"; desc = "Go to definition"; }
      { mode = "n"; key = "gr"; action = ":Telescope lsp_references<CR>"; desc = "Go to references"; }
      { mode = "n"; key = "gi"; action = ":Telescope lsp_implementations<CR>"; desc = "Go to implementation"; }
      { mode = "n"; key = "gt"; action = ":Telescope lsp_type_definitions<CR>"; desc = "Go to type definition"; }
      { mode = "n"; key = "K"; action = "<cmd>lua vim.lsp.buf.hover()<CR>"; desc = "Hover documentation"; }
      { mode = "n"; key = "<leader>ca"; action = "<cmd>lua vim.lsp.buf.code_action()<CR>"; desc = "Code actions"; }
      { mode = "n"; key = "<leader>rn"; action = "<cmd>lua vim.lsp.buf.rename()<CR>"; desc = "Rename symbol"; }
      { mode = "n"; key = "<leader>d"; action = "<cmd>lua vim.diagnostic.open_float()<CR>"; desc = "Show diagnostics"; }
      { mode = "n"; key = "[d"; action = "<cmd>lua vim.diagnostic.goto_prev()<CR>"; desc = "Previous diagnostic"; }
      { mode = "n"; key = "]d"; action = "<cmd>lua vim.diagnostic.goto_next()<CR>"; desc = "Next diagnostic"; }
      { mode = "n"; key = "<leader>mp"; action = "<cmd>lua require('conform').format({ lsp_fallback = true })<CR>"; desc = "Format document"; }
      { mode = "n"; key = "<leader>gg"; action = ":LazyGit<CR>"; desc = "Open LazyGit"; }
      { mode = "n"; key = "<leader>nh"; action = ":nohl<CR>"; desc = "Clear search highlights"; }
    ];
  };
  
  # Generate embedded Lua configuration
  initLua = ''
    -- Set leader keys early
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "vim.g.${k} = ${lib.generators.toLua {} v}") neovimConfig.globals)}
    
    -- Set options
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "vim.opt.${k} = ${lib.generators.toLua {} v}") neovimConfig.options)}
    
    -- Keymaps
    ${lib.concatStringsSep "\n" (map (keymap: 
      "vim.keymap.set('${keymap.mode}', '${keymap.key}', '${keymap.action}', { desc = '${keymap.desc}' })"
    ) neovimConfig.keymaps)}
    
    -- LSP Configuration
    local lspconfig = require('lspconfig')
    local capabilities = require('cmp_nvim_lsp').default_capabilities()
    
    -- Enhanced capabilities
    capabilities.textDocument.completion.completionItem.snippetSupport = true
    
    -- LSP servers setup
    local servers = {
      lua_ls = {
        settings = {
          Lua = {
            runtime = { version = 'LuaJIT' },
            diagnostics = { globals = { 'vim' } },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),
              checkThirdParty = false,
            },
            telemetry = { enable = false },
          },
        },
      },
      nil_ls = {},
      pyright = {},
      rust_analyzer = {
        settings = {
          ["rust-analyzer"] = {
            cargo = { buildScripts = { enable = true } },
            procMacro = { enable = true },
          },
        },
      },
      ts_ls = {},
      html = {},
      cssls = {},
      jsonls = {},
      bashls = {},
      marksman = {},
    }
    
    for server, config in pairs(servers) do
      config.capabilities = capabilities
      lspconfig[server].setup(config)
    end
    
    -- Completion setup
    local cmp = require('cmp')
    local luasnip = require('luasnip')
    
    cmp.setup({
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      sources = cmp.config.sources({
        { name = 'nvim_lsp', priority = 1000 },
        { name = 'luasnip', priority = 750 },
        { name = 'buffer', priority = 500 },
        { name = 'path', priority = 250 },
      }),
      mapping = cmp.mapping.preset.insert({
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.abort(),
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
        ['<Tab>'] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          else
            fallback()
          end
        end, {'i', 's'}),
        ['<S-Tab>'] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
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
    
    -- Plugin configurations
    require('neo-tree').setup({
      close_if_last_window = true,
      enable_git_status = true,
      enable_diagnostics = true,
      window = {
        width = 35,
        mappings = {
          [" "] = "none",
        },
      },
      filesystem = {
        follow_current_file = {
          enabled = true,
        },
        use_libuv_file_watcher = true,
      },
    })
    
    require('telescope').setup({
      defaults = {
        file_ignore_patterns = { "node_modules", ".git", "target", "build" },
        vimgrep_arguments = {
          "rg", "--color=never", "--no-heading", "--with-filename",
          "--line-number", "--column", "--smart-case"
        },
      },
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
        }
      }
    })
    
    pcall(require('telescope').load_extension, 'fzf')
    
    require('nvim-treesitter.configs').setup({
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      indent = {
        enable = true,
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      },
    })
    
    require('lualine').setup({
      options = {
        theme = 'auto',
        globalstatus = true,
        component_separators = { left = '|', right = '|' },
        section_separators = { left = '''', right = '''' },
      },
      sections = {
        lualine_a = {'mode'},
        lualine_b = {'branch', 'diff', 'diagnostics'},
        lualine_c = {{'filename', path = 1}},
        lualine_x = {'encoding', 'fileformat', 'filetype'},
        lualine_y = {'progress'},
        lualine_z = {'location'}
      },
    })
    
    require('gitsigns').setup({
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    })
    
    require('which-key').setup({
      plugins = {
        spelling = { enabled = true, suggestions = 20 },
      },
    })
    
    require('nvim-autopairs').setup({
      check_ts = true,
      ts_config = {
        lua = {'string', 'source'},
        javascript = {'string', 'template_string'},
      },
    })
    
    require('Comment').setup()
    
    require('conform').setup({
      formatters_by_ft = {
        lua = { "stylua" },
        nix = { "alejandra" },
        python = { "black" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        rust = { "rustfmt" },
        html = { "prettier" },
        css = { "prettier" },
        json = { "prettier" },
        markdown = { "prettier" },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
    })
    
    -- Diagnostics configuration
    vim.diagnostic.config({
      virtual_text = {
        enabled = true,
        prefix = "●",
        severity = vim.diagnostic.severity.ERROR,
      },
      signs = true,
      underline = true,
      update_in_insert = false,
      severity_sort = true,
      float = {
        border = "rounded",
        source = "always",
        header = "",
        prefix = "",
      },
    })
    
    -- LSP diagnostic signs
    local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
    for type, icon in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
    end
    
    -- Autocommands
    local augroup = vim.api.nvim_create_augroup
    local autocmd = vim.api.nvim_create_autocmd
    
    augroup("YankHighlight", { clear = true })
    autocmd("TextYankPost", {
      group = "YankHighlight",
      callback = function()
        vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
      end,
    })
    
    augroup("RemoveWhitespace", { clear = true })
    autocmd("BufWritePre", {
      group = "RemoveWhitespace",
      pattern = "*",
      command = ":%s/\\s\\+$//e",
    })
    
    augroup("CloseWithQ", { clear = true })
    autocmd("FileType", {
      group = "CloseWithQ",
      pattern = { "help", "startuptime", "qf", "lspinfo" },
      command = "nnoremap <buffer><silent> q :close<CR>",
    })
    
    augroup("AutoResize", { clear = true })
    autocmd("VimResized", {
      group = "AutoResize",
      command = "tabdo wincmd =",
    })
  '';
  
  # Custom Neovim package
  customNeovim = pkgs.neovim.override {
    configure = {
      customRC = initLua;
      packages.myVimPackage = {
        start = neovimPlugins;
      };
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
        
        # Custom Neovim with configuration
        customNeovim
      ] ++ lspPackages ++ lib.optionals cfg.neovide [
        neovide
      ];
    };
  };
}