{
  config,
  pkgs,
  lib,
  profile,
  ...
}: {
  # Configure Neovim via the "programs.neovim" option.
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Extra packages needed for formatters, language servers,
    # and other utilities (such as Telescope dependencies)
    extraPackages = with pkgs; [
      # Formatters and linters
      stylua
      ruff
      nodePackages.prettier
      nodePackages.prettier-plugin-toml
      shfmt
      vim-vint

      # Utilities for Telescope (fuzzy finder) and more
      ripgrep
      fd
      aider-chat
    ];

    # Define all plugins with their configurations.
    plugins = with pkgs.vimPlugins; [
      # Basic plugins (loaded without extra configuration)
      gruvbox-material
      plenary-nvim
      cmp-buffer
      cmp-path
      cmp-nvim-lsp

      # ============================================================
      # File Explorer: nvim-tree-lua
      # ============================================================
      {
        plugin = nvim-tree-lua;
        type = "lua";
        config = ''
          -- Setup nvim-tree with adaptive size,
          -- git file status highlighting and filtering out dotfiles.
          require('nvim-tree').setup {
            view = { adaptive_size = true },
            renderer = { highlight_git = true },
            filters = { dotfiles = true },
          }
        '';
      }

      # ============================================================
      # Fuzzy Finder: Telescope
      # ============================================================
      {
        plugin = telescope-nvim;
        type = "lua";
        config = ''
          -- Configure Telescope with fzy sorters and ignore "node_modules"
          require('telescope').setup {
            defaults = {
              file_sorter    = require('telescope.sorters').get_fzy_sorter,
              generic_sorter = require('telescope.sorters').get_generic_fzy_sorter,
              file_ignore_patterns = { 'node_modules' },
            },
          }
        '';
      }

      # ============================================================
      # Syntax Highlighting & Parsing: Treesitter
      # ============================================================
      {
        plugin = nvim-treesitter.withAllGrammars;
        type = "lua";
        config = ''
          -- Enable Treesitter-based syntax highlighting.
          require('nvim-treesitter.configs').setup {
            highlight = { enable = true },
          }
        '';
      }

      # ============================================================
      # AI & Snippet Assistance: Supermaven
      # ============================================================
      {
        plugin = supermaven-nvim;
        type = "lua";
        config = ''
          -- Setup Supermaven for inline AI code suggestions,
          -- along with custom key mappings.
          require("supermaven-nvim").setup({
            keymaps = {
              accept_suggestion = "<Tab>",
              clear_suggestion  = "<C-]>",
              accept_word       = "<C-j>",
            },
            ignore_filetypes = { cpp = true },
            color = { suggestion_color = "#ff88dd" },
            use_default_keymaps = false,
            enable_cmp = true,
          })
        '';
      }

      # ============================================================
      # Cheatsheet: Quick command reference
      # ============================================================
      {
        plugin = cheatsheet-nvim;
        type = "lua";
        config = ''
          require('cheatsheet').setup()
        '';
      }

      # ============================================================
      # UI Management: Edgy
      # ============================================================
      {
        plugin = edgy-nvim;
        type = "lua";
        config = ''
          require('edgy').setup({})
        '';
      }

      # ============================================================
      # Formatting: Formatter.nvim
      # ============================================================
      {
        plugin = formatter-nvim;
        type = "lua";
        config = ''
          -- Formatter configuration
          -- Define a helper for all web-related filetypes to use Prettier.
          local function prettier()
            return {
              exe  = 'prettier-daemon',
              args = { vim.api.nvim_buf_get_name(0) }
            }
          end

          require('formatter').setup({
            filetype = {
              -- Web and markup files use Prettier.
              typescript = { prettier },
              javascript = { prettier },
              json       = { prettier },
              css        = { prettier },
              scss       = { prettier },
              html       = { prettier },
              markdown = { prettier },
              -- Language-specific formatters:
              lua = {
                function()
                  return {
                    exe  = 'stylua',
                    args = { '--config-path', '~/.config/stylua/stylua.toml' }
                  }
                end
              },
              python = {
                function()
                  return {
                    exe  = 'ruff',
                    args = { '-' }
                  }
                end
              },
              sh = {
                function()
                  return {
                    exe  = 'shfmt',
                    args = { '-w' }
                  }
                end
              },
              vim = {
                function()
                  return {
                    exe = 'vint'
                  }
                end
              }
            }
          })
        '';
      }

      # ============================================================
      # Diagnostic Window: Trouble.nvim
      # ============================================================
      {
        plugin = trouble-nvim;
        type = "lua";
        config = ''
          require('trouble').setup({})
        '';
      }

      # ============================================================
      # Completion Engine: nvim-cmp
      # ============================================================
      {
        plugin = nvim-cmp;
        type = "lua";
        config = ''
          local cmp = require('cmp')
          cmp.setup({
            sources = cmp.config.sources({
              { name = 'nvim_lsp' },
              { name = 'buffer' },
              { name = 'path' },
              { name = 'supermaven' },
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
                else
                  fallback()
                end
              end, { 'i', 's' }),
              ['<S-Tab>'] = cmp.mapping(function(fallback)
                if cmp.visible() then
                  cmp.select_prev_item()
                else
                  fallback()
                end
              end, { 'i', 's' })
            })
          })
        '';
      }

      # ============================================================
      # Obsidian: Note-taking integration
      # ============================================================
      {
        plugin = obsidian-nvim;
        type = "lua";
        config = ''
          -- Set conceallevel to improve markdown link display.
          vim.opt.conceallevel = 1
          require("obsidian").setup({
            workspaces = {
              {
                name = "personal",
                path = "~/Obsidian",
              },
            },
            notes_subdir = "notes",
            daily_notes = {
              folder = "notes/dailies",
              date_format = "%Y-%m-%d",
            },
            completion = {
              nvim_cmp = pcall(require, 'cmp'),
              min_chars = 2,
            },
            new_notes_location = "notes_subdir",
            wiki_link_func = function(opts)
              return require("obsidian.util").wiki_link_id_prefix(opts)
            end,
            preferred_link_style = "wiki",
            ui = {
              enable = true,
            },
          })
        '';
      }

      # ============================================================
      # Indentation Guides: indent-blankline / ibl
      # ============================================================
      {
        plugin = indent-blankline-nvim;
        type = "lua";
        config = ''
          require('ibl').setup()
        '';
      }

      # ============================================================
      # Key Mapping Helper: which-key.nvim
      # ============================================================
      {
        plugin = which-key-nvim;
        type = "lua";
        config = ''
          require('which-key').setup{}
        '';
      }

      # ============================================================
      # Git Signs: gitsigns.nvim
      # ============================================================
      {
        plugin = gitsigns-nvim;
        type = "lua";
        config = ''
          require('gitsigns').setup{
            signs = {
              add         = { text = '+' },
              change      = { text = '~' },
              delete      = { text = '_' },
              topdelete   = { text = '‾' },
              changedelete= { text = '~' },
            },
          }
        '';
      }

      # ============================================================
      # Statusline: lualine.nvim
      # ============================================================
      {
        plugin = lualine-nvim;
        type = "lua";
        config = ''
          require('lualine').setup{
            options = {
              theme = 'gruvbox-material',
              component_separators = '|',
              section_separators   = ""  -- Use double quotes to avoid ending the Nix string literal early
            }
          }
        '';
      }

      # ============================================================
      # AI Assistance: aider.nvim
      # ============================================================
      {
        plugin = aider-nvim;
        type = "lua";
        config = ''
          require('aider').setup({
            auto_manage_context = true,
            default_bindings = true,
            debug = false,
            ignore_buffers = {
              '^term:',
              'NeogitConsole',
              'NvimTree_',
              'neo-tree filesystem'
            }
          })
        '';
      }
    ];

    # ===============================================
    # Global Extra Lua Configuration for Neovim
    # ===============================================
    extraLuaConfig = ''
      -- Basic settings: enable system clipboard and show line numbers.
      vim.opt.clipboard = 'unnamedplus'
      vim.opt.number = true
      vim.g.mapleader = ','

      -- Visual theme and effects.
      vim.o.termguicolors = true
      vim.o.background = 'dark'
      vim.g.gruvbox_material_transparent_background = 1
      vim.g.gruvbox_material_better_performance       = 1
      vim.opt.winblend = 10   -- Slight transparency for floating windows
      vim.opt.pumblend = 10   -- Slight transparency for popup menus

      -- Helper for mapping keys
      local function map(mode, lhs, rhs, opts)
        local options = { noremap = true, silent = true }
        if opts then
          options = vim.tbl_extend('force', options, opts)
        end
        vim.keymap.set(mode, lhs, rhs, options)
      end

      -- File navigation shortcuts (Telescope and NvimTree)
      map('n', '<leader>pv', ':NvimTreeToggle<CR>')
      map('n', '<leader>ff', '<cmd>Telescope find_files<cr>')
      map('n', '<leader>fg', '<cmd>Telescope live_grep<cr>')
      map('n', '<leader>fb', '<cmd>Telescope buffers<cr>')
      map('n', '<leader>fh', '<cmd>Telescope help_tags<cr>')

      -- Obsidian note management shortcuts.
      map('n', '<leader>on', ':ObsidianNew<CR>', { desc = "New Obsidian note" })
      map('n', '<leader>oo', ':ObsidianOpen<CR>', { desc = "Open Obsidian" })
      map('n', '<leader>os', ':ObsidianQuickSwitch<CR>', { desc = "Quick Switch" })
      map('n', '<leader>of', ':ObsidianFollowLink<CR>', { desc = "Follow Link" })
      map('n', '<leader>ob', ':ObsidianBacklinks<CR>', { desc = "Show Backlinks" })

      -- Set the colorscheme.
      vim.cmd('colorscheme gruvbox-material')

      -- Create an autocommand group for custom behaviors.
      local augroup = vim.api.nvim_create_augroup("CustomAutocommands", { clear = true })

      -- Autoformat on file save.
      vim.api.nvim_create_autocmd("BufWritePost", {
        group   = augroup,
        pattern = "*",
        command = "FormatWrite",
      })

      -- Highlight yanked text briefly.
      vim.api.nvim_create_autocmd("TextYankPost", {
        group = augroup,
        callback = function()
          vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })
        end,
      })

      -- Create command aliases for Aider
      vim.api.nvim_create_user_command('AiderChat', 'terminal aider', {})
      vim.api.nvim_create_user_command('AiderAddModifiedFiles', 'terminal aider $(git ls-files --modified)', {})
      vim.api.nvim_create_user_command('AiderOpen', 'terminal aider', {})
      vim.api.nvim_create_user_command('AiderOpenGPT3', 'terminal aider -3', {})
      vim.api.nvim_create_user_command('AiderOpenNoAutoCommit', 'terminal AIDER_NO_AUTO_COMMITS=1 aider', {})
    '';
  };
}
