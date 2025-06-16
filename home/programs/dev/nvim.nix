###############################################################################
# Neovim Development Module (Maid Version)
# Installs Neovim and essential development tools using nix-maid package management
###############################################################################
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.home.programs.dev.nvim;

  # Configuration using toLua with data and mkLuaInline
  nvimConfig = {
    # Vim settings as pure data
    settings = {
      clipboard = "unnamedplus";
      number = true;
      relativenumber = true;
      expandtab = true;
      tabstop = 2;
      shiftwidth = 2;
      termguicolors = true;
      background = "dark";
      conceallevel = 1;
    };

    # Global variables as data
    globals = {
      mapleader = ",";
      gruvbox_material_transparent_background = 1;
      gruvbox_material_better_performance = 1;
    };

    # Keymaps as data
    keymaps = [
      {
        mode = "n";
        lhs = "<leader>e";
        rhs = ":NvimTreeToggle<CR>";
        desc = "Toggle file explorer";
      }
      {
        mode = "n";
        lhs = "<leader>ef";
        rhs = ":NvimTreeFocus<CR>";
        desc = "Focus file explorer";
      }
      {
        mode = "n";
        lhs = "<leader>er";
        rhs = ":NvimTreeRefresh<CR>";
        desc = "Refresh file explorer";
      }
      {
        mode = "n";
        lhs = "<leader>ff";
        rhs = "<cmd>Telescope find_files<cr>";
        desc = "Find files";
      }
      {
        mode = "n";
        lhs = "<leader>fg";
        rhs = "<cmd>Telescope live_grep<cr>";
        desc = "Live grep";
      }
      {
        mode = "n";
        lhs = "<leader>fb";
        rhs = "<cmd>Telescope buffers<cr>";
        desc = "Find buffers";
      }
      {
        mode = "n";
        lhs = "<leader>fh";
        rhs = "<cmd>Telescope help_tags<cr>";
        desc = "Help tags";
      }
      {
        mode = "n";
        lhs = "<leader>on";
        rhs = ":ObsidianNew<CR>";
        desc = "New note";
      }
      {
        mode = "n";
        lhs = "<leader>os";
        rhs = ":ObsidianQuickSwitch<CR>";
        desc = "Quick switch";
      }
      {
        mode = "n";
        lhs = "<leader>of";
        rhs = ":ObsidianFollowLink<CR>";
        desc = "Follow link";
      }
      {
        mode = "n";
        lhs = "<leader>f";
        rhs = ":Format<CR>";
        desc = "Format file";
      }
    ];

    # Plugin configurations as data
    plugins = {
      nvim_tree = {
        disable_netrw = true;
        hijack_netrw = true;
        open_on_tab = false;
        hijack_cursor = false;
        update_cwd = true;
        view = {
          adaptive_size = false;
          width = 40;
          side = "left";
          preserve_window_proportions = true;
        };
        renderer = {
          highlight_git = true;
          icons = {
            show = {
              file = true;
              folder = true;
              folder_arrow = true;
              git = true;
            };
          };
        };
        filters = {
          dotfiles = false;
          custom = [".git" "node_modules" ".cache"];
        };
        git = {
          enable = true;
          ignore = false;
        };
        actions = {
          open_file = {
            quit_on_open = true;
            resize_window = false;
          };
        };
        update_focused_file = {
          enable = true;
          update_root = false;
        };
      };

      telescope = {
        defaults = {
          file_ignore_patterns = ["node_modules"];
        };
      };

      treesitter = {
        highlight = {enable = true;};
        indent = {enable = true;};
      };

      cmp = {
        sources = [
          {name = "nvim_lsp";}
          {name = "buffer";}
          {name = "path";}
        ];
        mapping = {
          "C-b" = "scroll_docs(-4)";
          "C-f" = "scroll_docs(4)";
          "C-Space" = "complete()";
          "C-e" = "abort()";
          "CR" = "confirm({ select = true })";
        };
      };

      obsidian = {
        workspaces = [
          {
            name = "personal";
            path = "~/Obsidian";
          }
        ];
        notes_subdir = "notes";
        daily_notes = {
          folder = "notes/dailies";
          date_format = "%Y-%m-%d";
        };
        disable_frontmatter = true;
        completion = {
          nvim_cmp = true;
          min_chars = 2;
        };
        new_notes_location = "notes_subdir";
        preferred_link_style = "wiki";
        ui = {
          enable = true;
          update_debounce = 200;
        };
        attachments = {
          img_folder = "assets/imgs";
        };
      };

      gitsigns = {
        signs = {
          add = {text = "+";};
          change = {text = "~";};
          delete = {text = "_";};
          topdelete = {text = "‾";};
          changedelete = {text = "~";};
        };
      };

      lualine = {
        options = {
          theme = "gruvbox-material";
          component_separators = "|";
          section_separators = "";
        };
      };
    };

    # Executable setup code using mkLuaInline
    setup = lib.generators.mkLuaInline ''
      -- Apply settings
      for k, v in pairs(settings) do
        vim.opt[k] = v
      end

      -- Apply globals
      for k, v in pairs(globals) do
        vim.g[k] = v
      end

      -- Apply keymaps
      for _, keymap in ipairs(keymaps) do
        vim.keymap.set(keymap.mode, keymap.lhs, keymap.rhs, {
          noremap = true,
          silent = true,
          desc = keymap.desc
        })
      end

      -- Set colorscheme
      vim.cmd('colorscheme gruvbox-material')

      -- Setup autocommands
      local augroup = vim.api.nvim_create_augroup("NvimConfig", { clear = true })

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

      vim.api.nvim_create_autocmd("VimLeavePre", {
        group = augroup,
        callback = function()
          pcall(vim.cmd, 'wall')
        end,
      })

      -- Setup plugins
      require('nvim-tree').setup(plugins.nvim_tree)
      require('telescope').setup(plugins.telescope)
      require('nvim-treesitter.configs').setup(plugins.treesitter)

      -- CMP setup (more complex mapping)
      local cmp = require('cmp')
      local cmp_config = plugins.cmp
      cmp_config.mapping = cmp.mapping.preset.insert({
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
      cmp.setup(cmp_config)

      -- Formatter setup
      require('formatter').setup({
        filetype = {
          typescript = {
            function()
              return {
                exe = 'prettier',
                args = { '--stdin-filepath', vim.api.nvim_buf_get_name(0) },
                stdin = true
              }
            end
          },
          javascript = {
            function()
              return {
                exe = 'prettier',
                args = { '--stdin-filepath', vim.api.nvim_buf_get_name(0) },
                stdin = true
              }
            end
          },
          json = {
            function()
              return {
                exe = 'prettier',
                args = { '--stdin-filepath', vim.api.nvim_buf_get_name(0) },
                stdin = true
              }
            end
          },
          css = {
            function()
              return {
                exe = 'prettier',
                args = { '--stdin-filepath', vim.api.nvim_buf_get_name(0) },
                stdin = true
              }
            end
          },
          html = {
            function()
              return {
                exe = 'prettier',
                args = { '--stdin-filepath', vim.api.nvim_buf_get_name(0) },
                stdin = true
              }
            end
          },
          markdown = {
            function()
              return {
                exe = 'prettier',
                args = { '--stdin-filepath', vim.api.nvim_buf_get_name(0) },
                stdin = true
              }
            end
          },
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

      -- Setup remaining plugins
      require("obsidian").setup(plugins.obsidian)
      require('ibl').setup()
      require('which-key').setup{}
      require('gitsigns').setup(plugins.gitsigns)
      require("lualine").setup(plugins.lualine)
    '';
  };
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.programs.dev.nvim = {
    enable = lib.mkEnableOption "Neovim editor";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Maid Configuration
    ###########################################################################
    users.users.y0usaf.maid = {
      packages = with pkgs; [
        neovim

        # Essential development tools
        ripgrep
        fd
        stylua
        ruff
        nodePackages.prettier
        shfmt
      ];

      ###########################################################################
      # Configuration Files
      ###########################################################################
      file.xdg_config = {
        "nvim/init.lua".text = lib.generators.toLua {} nvimConfig;
      };
    };
  };
}
