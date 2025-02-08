{
  config,
  pkgs,
  lib,
  profile,
  ...
}: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    extraPackages = with pkgs; [
      # Language servers and formatters
      stylua
      black
      nodePackages.prettier
      nodePackages.prettier-plugin-toml
      shfmt
      vim-vint

      # For telescope dependencies
      ripgrep
      fd
    ];

    plugins = with pkgs.vimPlugins; [
      # Basic plugins without config
      gruvbox-material
      plenary-nvim
      cmp-buffer
      cmp-path
      cmp-nvim-lsp

      # Plugins with configuration
      {
        plugin = nvim-tree-lua;
        type = "lua";
        config = ''
          require('nvim-tree').setup {
            view = { adaptive_size = true },
            renderer = { highlight_git = true },
            filters = { dotfiles = true }
          }
        '';
      }

      {
        plugin = telescope-nvim;
        type = "lua";
        config = ''
          require('telescope').setup {
            defaults = {
              file_sorter = require('telescope.sorters').get_fzy_sorter,
              generic_sorter = require('telescope.sorters').get_generic_fzy_sorter,
              file_ignore_patterns = { 'node_modules' },
            },
          }
        '';
      }

      {
        plugin = nvim-treesitter.withAllGrammars;
        type = "lua";
        config = ''
          require('nvim-treesitter.configs').setup {
            highlight = { enable = true },
          }
        '';
      }

      # Supermaven
      {
        plugin = supermaven-nvim;
        type = "lua";
        config = ''
          require("supermaven-nvim").setup({
            keymaps = {
              accept_suggestion = "<Tab>",
              clear_suggestion = "<C-]>",
              accept_word = "<C-j>",
            },
            ignore_filetypes = { cpp = true },
            color = { suggestion_color = "#ff88dd" },
            use_default_keymaps = false,
            enable_cmp = true,
          })
        '';
      }

      # Cheatsheet
      {
        plugin = cheatsheet-nvim;
        type = "lua";
        config = ''
          require('cheatsheet').setup()
        '';
      }

      # Edgy
      {
        plugin = edgy-nvim;
        type = "lua";
        config = ''
          require('edgy').setup({})
        '';
      }

      # Formatter
      {
        plugin = formatter-nvim;
        type = "lua";
        config = ''
          require('formatter').setup({
            filetype = {
              typescript = {
                function()
                  return {
                    exe = 'prettier-daemon',
                    args = { vim.api.nvim_buf_get_name(0) }
                  }
                end
              },
              javascript = {
                function()
                  return {
                    exe = 'prettier-daemon',
                    args = { vim.api.nvim_buf_get_name(0) }
                  }
                end
              },
              json = {
                function()
                  return {
                    exe = 'prettier-daemon',
                    args = { vim.api.nvim_buf_get_name(0) }
                  }
                end
              },
              css = {
                function()
                  return {
                    exe = 'prettier-daemon',
                    args = { vim.api.nvim_buf_get_name(0) }
                  }
                end
              },
              scss = {
                function()
                  return {
                    exe = 'prettier-daemon',
                    args = { vim.api.nvim_buf_get_name(0) }
                  }
                end
              },
              html = {
                function()
                  return {
                    exe = 'prettier-daemon',
                    args = { vim.api.nvim_buf_get_name(0) }
                  }
                end
              },
              markdown = {
                function()
                  return {
                    exe = 'prettier-daemon',
                    args = { vim.api.nvim_buf_get_name(0) }
                  }
                end
              },
              lua = {
                function()
                  return {
                    exe = 'stylua',
                    args = { '--config-path', '~/.config/stylua/stylua.toml' }
                  }
                end
              },
              python = {
                function()
                  return {
                    exe = 'black',
                    args = { '-' }
                  }
                end
              },
              sh = {
                function()
                  return {
                    exe = 'shfmt',
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

      # Trouble
      {
        plugin = trouble-nvim;
        type = "lua";
        config = ''
          require('trouble').setup({})
        '';
      }

      # Completion
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

      # Obsidian
      {
        plugin = obsidian-nvim;
        type = "lua";
        config = ''
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
    ];

    extraLuaConfig = ''
      -- Basic options
      vim.opt.clipboard = 'unnamedplus'
      vim.opt.number = true
      vim.g.mapleader = ','

      -- Key mappings
      local function map(mode, lhs, rhs, opts)
        local options = { noremap = true, silent = true }
        if opts then options = vim.tbl_extend('force', options, opts) end
        vim.keymap.set(mode, lhs, rhs, options)
      end

      -- File navigation
      map('n', '<leader>pv', ':NvimTreeToggle<CR>')
      map('n', '<leader>ff', '<cmd>Telescope find_files<cr>')
      map('n', '<leader>fg', '<cmd>Telescope live_grep<cr>')
      map('n', '<leader>fb', '<cmd>Telescope buffers<cr>')
      map('n', '<leader>fh', '<cmd>Telescope help_tags<cr>')

      -- Obsidian mappings
      map('n', '<leader>on', ':ObsidianNew<CR>', { desc = "New Obsidian note" })
      map('n', '<leader>oo', ':ObsidianOpen<CR>', { desc = "Open Obsidian" })
      map('n', '<leader>os', ':ObsidianQuickSwitch<CR>', { desc = "Quick Switch" })
      map('n', '<leader>of', ':ObsidianFollowLink<CR>', { desc = "Follow Link" })
      map('n', '<leader>ob', ':ObsidianBacklinks<CR>', { desc = "Show Backlinks" })

      -- Theme
      vim.cmd('colorscheme gruvbox-material')

      -- Autocommands
      local augroup = vim.api.nvim_create_augroup("CustomAutocommands", { clear = true })

      vim.api.nvim_create_autocmd("BufWritePost", {
        group = augroup,
        pattern = "*",
        command = "FormatWrite",
      })

      vim.api.nvim_create_autocmd("TextYankPost", {
        group = augroup,
        callback = function()
          vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })
        end,
      })
    '';
  };
}
