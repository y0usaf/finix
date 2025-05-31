###############################################################################
# Neovim Configuration Module - Minimalist Edition
# Clean, fast Neovim setup focused on core functionality
# - Essential plugins for development workflow
# - No background AI processes that cause shutdown delays
# - Streamlined configuration for better performance
###############################################################################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.cfg.dev.nvim;
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.cfg.dev.nvim = {
    enable = lib.mkEnableOption "neovim editor";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Neovim Configuration
    ###########################################################################
    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;

      # Essential packages for development
      extraPackages = with pkgs; [
        # Formatters and linters
        stylua
        ruff
        nodePackages.prettier
        shfmt

        # Core utilities
        ripgrep
        fd
        # Removed aider-chat to reduce complexity
      ];

      # Streamlined plugin selection
      plugins = with pkgs.vimPlugins; [
        # Core plugins
        gruvbox-material
        plenary-nvim

        # Completion
        cmp-buffer
        cmp-path
        cmp-nvim-lsp
        nvim-cmp

        # ============================================================
        # File Explorer: nvim-tree-lua (Always Visible)
        # ============================================================
        {
          plugin = nvim-tree-lua;
          type = "lua";
          config = ''
            require('nvim-tree').setup {
              -- Auto-open on startup
              view = {
                adaptive_size = true,
                width = 30,
                side = "left",
                preserve_window_proportions = true,
              },
              renderer = {
                highlight_git = true,
                icons = {
                  show = {
                    file = true,
                    folder = true,
                    folder_arrow = true,
                    git = true,
                  },
                },
              },
              filters = {
                dotfiles = false,  -- Show dotfiles by default
                custom = { ".git", "node_modules", ".cache" },
              },
              git = {
                enable = true,
                ignore = false,
              },
              actions = {
                open_file = {
                  quit_on_open = false,  -- Keep tree open when opening files
                  resize_window = true,
                },
              },
              update_focused_file = {
                enable = true,
                update_root = false,
              },
              -- Auto-open behavior
              hijack_directories = {
                enable = true,
                auto_open = true,
              },
            }

            -- Auto-open nvim-tree on startup
            local function open_nvim_tree()
              require("nvim-tree.api").tree.open()
            end

            vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree })
          '';
        }

        # ============================================================
        # Fuzzy Finder: Telescope
        # ============================================================
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

        # ============================================================
        # Syntax Highlighting: Treesitter
        # ============================================================
        {
          plugin = nvim-treesitter.withAllGrammars;
          type = "lua";
          config = ''
            require('nvim-treesitter.configs').setup {
              highlight = { enable = true },
              indent = { enable = true },
            }
          '';
        }

        # ============================================================
        # Formatting: Formatter.nvim
        # ============================================================
        {
          plugin = formatter-nvim;
          type = "lua";
          config = ''
            local function prettier()
              return {
                exe = 'prettier',
                args = { '--stdin-filepath', vim.api.nvim_buf_get_name(0) },
                stdin = true
              }
            end

            require('formatter').setup({
              filetype = {
                typescript = { prettier },
                javascript = { prettier },
                json = { prettier },
                css = { prettier },
                html = { prettier },
                markdown = { prettier },
                lua = {
                  function()
                    return {
                      exe = 'stylua',
                      args = { '--stdin-filepath', vim.api.nvim_buf_get_name(0), '-' },
                      stdin = true
                    }
                  end
                },
                python = {
                  function()
                    return {
                      exe = 'ruff',
                      args = { 'format', '-' },
                      stdin = true
                    }
                  end
                },
                sh = {
                  function()
                    return {
                      exe = 'shfmt',
                      args = { '-' },
                      stdin = true
                    }
                  end
                }
              }
            })
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
        # Obsidian: Minimal note-taking integration
        # ============================================================
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

              -- Disable automatic daily notes creation
              daily_notes = {
                folder = "notes/dailies",
                date_format = "%Y-%m-%d",
                template = nil,  -- No template
              },
              disable_frontmatter = true,  -- Disable frontmatter creation

              completion = {
                nvim_cmp = true,
                min_chars = 2,
              },
              new_notes_location = "notes_subdir",

              -- Simplified link handling
              wiki_link_func = function(opts)
                return require("obsidian.util").wiki_link_id_prefix(opts)
              end,
              preferred_link_style = "wiki",

              ui = {
                enable = true,
                update_debounce = 200,
                checkboxes = {},  -- Disable checkbox rendering
              },

              -- Disable automatic features that create files/dirs
              attachments = {
                img_folder = "assets/imgs",
              },

              -- Don't auto-create directories
              note_id_func = function(title)
                return title
              end,
            })
          '';
        }

        # ============================================================
        # Essential UI plugins
        # ============================================================
        {
          plugin = indent-blankline-nvim;
          type = "lua";
          config = ''
            require('ibl').setup()
          '';
        }

        {
          plugin = which-key-nvim;
          type = "lua";
          config = ''
            require('which-key').setup{}
          '';
        }

        {
          plugin = gitsigns-nvim;
          type = "lua";
          config = ''
            require('gitsigns').setup{
              signs = {
                add = { text = '+' },
                change = { text = '~' },
                delete = { text = '_' },
                topdelete = { text = '‾' },
                changedelete = { text = '~' },
              },
            }
          '';
        }

        {
          plugin = lualine-nvim;
          type = "lua";
          config = ''
            require("lualine").setup{
              options = {
                theme = "gruvbox-material",
                component_separators = "|",
                section_separators = ""
              }
            }
          '';
        }
      ];

      # ===============================================
      # Clean Lua Configuration
      # ===============================================
      extraLuaConfig = ''
        -- Basic settings
        vim.opt.clipboard = 'unnamedplus'
        vim.opt.number = true
        vim.opt.relativenumber = true
        vim.opt.expandtab = true
        vim.opt.shiftwidth = 2
        vim.opt.tabstop = 2
        vim.g.mapleader = ','

        -- Visual theme
        vim.o.termguicolors = true
        vim.o.background = 'dark'
        vim.g.gruvbox_material_transparent_background = 1
        vim.g.gruvbox_material_better_performance = 1

        -- Helper for mapping keys
        local function map(mode, lhs, rhs, opts)
          local options = { noremap = true, silent = true }
          if opts then
            options = vim.tbl_extend('force', options, opts)
          end
          vim.keymap.set(mode, lhs, rhs, options)
        end

        -- File navigation shortcuts
        map('n', '<leader>e', ':NvimTreeToggle<CR>', { desc = "Toggle file explorer" })
        map('n', '<leader>ef', ':NvimTreeFocus<CR>', { desc = "Focus file explorer" })
        map('n', '<leader>er', ':NvimTreeRefresh<CR>', { desc = "Refresh file explorer" })
        map('n', '<leader>ff', '<cmd>Telescope find_files<cr>', { desc = "Find files" })
        map('n', '<leader>fg', '<cmd>Telescope live_grep<cr>', { desc = "Live grep" })
        map('n', '<leader>fb', '<cmd>Telescope buffers<cr>', { desc = "Find buffers" })
        map('n', '<leader>fh', '<cmd>Telescope help_tags<cr>', { desc = "Help tags" })

        -- Obsidian shortcuts (simplified)
        map('n', '<leader>on', ':ObsidianNew<CR>', { desc = "New note" })
        map('n', '<leader>os', ':ObsidianQuickSwitch<CR>', { desc = "Quick switch" })
        map('n', '<leader>of', ':ObsidianFollowLink<CR>', { desc = "Follow link" })

        -- Formatting shortcut
        map('n', '<leader>f', ':Format<CR>', { desc = "Format file" })

        -- Set colorscheme
        vim.cmd('colorscheme gruvbox-material')

        -- Autocommand group
        local augroup = vim.api.nvim_create_augroup("MinimalNvim", { clear = true })

        -- Auto-format on save
        vim.api.nvim_create_autocmd("BufWritePost", {
          group = augroup,
          pattern = "*",
          command = "FormatWrite",
        })

        -- Highlight yanked text
        vim.api.nvim_create_autocmd("TextYankPost", {
          group = augroup,
          callback = function()
            vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })
          end,
        })

        -- Clean exit (no background processes to worry about!)
        vim.api.nvim_create_autocmd("VimLeavePre", {
          group = augroup,
          callback = function()
            -- Just save all buffers, no complex cleanup needed
            pcall(vim.cmd, 'wall')
          end,
        })
      '';
    };
  };
}
