###############################################################################
# Neovim Configuration (NixVim)
# Modern Neovim setup with LSP, Telescope, and development tools
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
    enable = lib.mkEnableOption "NixVim editor";
    neovide = lib.mkEnableOption "Neovide GUI for Neovim";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  imports = [
    nixvim.nixosModules.nixvim
  ];
  
  config = lib.mkIf cfg.enable {
    ###########################################################################
    # Maid Configuration
    ###########################################################################
    users.users.${username}.maid = {
      packages = with pkgs; [
        # Conditionally add neovide package
      ] ++ lib.optionals cfg.neovide [
        neovide
      ];
    };
    
    ###########################################################################
    # NixVim Configuration
    ###########################################################################
    programs.nixvim = {
      enable = true;
      defaultEditor = true;
      
      ###########################################################################
      # Global Settings
      ###########################################################################
      globals.mapleader = ",";
      
      opts = {
        # Editor behavior
        clipboard = "unnamedplus";
        number = true;
        relativenumber = true;
        expandtab = true;
        tabstop = 2;
        shiftwidth = 2;
        termguicolors = true;
        background = "dark";
        conceallevel = 1;
        
        # Search
        ignorecase = true;
        smartcase = true;
        hlsearch = true;
        incsearch = true;
        
        # Interface
        signcolumn = "yes";
        updatetime = 300;
        timeoutlen = 500;
        completeopt = ["menu" "menuone" "noselect"];
      };

      ###########################################################################
      # Colorscheme
      ###########################################################################
      colorschemes.gruvbox = {
        enable = true;
        settings = {
          transparent_background = true;
          improved_strings = true;
          improved_warnings = true;
        };
      };

      ###########################################################################
      # Key Mappings
      ###########################################################################
      keymaps = [
        # File explorer
        {
          mode = "n";
          key = "<leader>e";
          action = "<cmd>NvimTreeToggle<CR>";
          options.desc = "Toggle file explorer";
        }
        {
          mode = "n";
          key = "<leader>ef";
          action = "<cmd>NvimTreeFocus<CR>";
          options.desc = "Focus file explorer";
        }
        
        # Telescope
        {
          mode = "n";
          key = "<leader>ff";
          action = "<cmd>Telescope find_files<CR>";
          options.desc = "Find files";
        }
        {
          mode = "n";
          key = "<leader>fg";
          action = "<cmd>Telescope live_grep<CR>";
          options.desc = "Live grep";
        }
        {
          mode = "n";
          key = "<leader>fb";
          action = "<cmd>Telescope buffers<CR>";
          options.desc = "Find buffers";
        }
        {
          mode = "n";
          key = "<leader>fh";
          action = "<cmd>Telescope help_tags<CR>";
          options.desc = "Help tags";
        }
        
        # LSP
        {
          mode = "n";
          key = "gd";
          action = "<cmd>Telescope lsp_definitions<CR>";
          options.desc = "Go to definition";
        }
        {
          mode = "n";
          key = "gr";
          action = "<cmd>Telescope lsp_references<CR>";
          options.desc = "Go to references";
        }
        {
          mode = "n";
          key = "K";
          action = "<cmd>lua vim.lsp.buf.hover()<CR>";
          options.desc = "Hover documentation";
        }
        {
          mode = "n";
          key = "<leader>ca";
          action = "<cmd>lua vim.lsp.buf.code_action()<CR>";
          options.desc = "Code actions";
        }
        {
          mode = "n";
          key = "<leader>rn";
          action = "<cmd>lua vim.lsp.buf.rename()<CR>";
          options.desc = "Rename symbol";
        }
        
        # Formatting
        {
          mode = "n";
          key = "<leader>f";
          action = "<cmd>lua vim.lsp.buf.format()<CR>";
          options.desc = "Format file";
        }
        
        # Obsidian (if using)
        {
          mode = "n";
          key = "<leader>on";
          action = "<cmd>ObsidianNew<CR>";
          options.desc = "New note";
        }
        {
          mode = "n";
          key = "<leader>os";
          action = "<cmd>ObsidianQuickSwitch<CR>";
          options.desc = "Quick switch";
        }
      ];

      ###########################################################################
      # Plugins Configuration
      ###########################################################################
      plugins = {
        # LSP
        lsp = {
          enable = true;
          servers = {
            lua-ls.enable = true;
            nil-ls.enable = true;
            pyright.enable = true;
            rust-analyzer = {
              enable = true;
              installRustc = true;
              installCargo = true;
            };
            tsserver.enable = true;
            html.enable = true;
            cssls.enable = true;
            jsonls.enable = true;
            bashls.enable = true;
          };
        };
        
        # Completion
        cmp = {
          enable = true;
          settings = {
            sources = [
              {name = "nvim_lsp";}
              {name = "buffer";}
              {name = "path";}
              {name = "cmdline";}
            ];
            mapping = {
              "<C-Space>" = "cmp.mapping.complete()";
              "<C-e>" = "cmp.mapping.abort()";
              "<CR>" = "cmp.mapping.confirm({ select = true })";
              "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
              "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
            };
          };
        };
        
        # File explorer
        nvim-tree = {
          enable = true;
          disableNetrw = true;
          hijackNetrw = true;
          hijackCursor = false;
          view = {
            width = 40;
            side = "left";
          };
          renderer = {
            highlightGit = true;
            icons = {
              show = {
                file = true;
                folder = true;
                folderArrow = true;
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
            openFile = {
              quitOnOpen = true;
              resizeWindow = false;
            };
          };
        };
        
        # Fuzzy finder
        telescope = {
          enable = true;
          settings = {
            defaults = {
              file_ignore_patterns = ["node_modules"];
              prompt_prefix = " ";
              selection_caret = " ";
            };
          };
          extensions = {
            fzf-native = {
              enable = true;
              settings = {
                fuzzy = true;
                override_generic_sorter = true;
                override_file_sorter = true;
              };
            };
          };
        };
        
        # Treesitter
        treesitter = {
          enable = true;
          settings = {
            highlight = {
              enable = true;
              additional_vim_regex_highlighting = false;
            };
            indent = {enable = true;};
            ensure_installed = [
              "lua"
              "nix"
              "python"
              "rust"
              "typescript"
              "javascript"
              "html"
              "css"
              "json"
              "yaml"
              "bash"
              "markdown"
            ];
          };
        };
        
        # Status line
        lualine = {
          enable = true;
          settings = {
            options = {
              theme = "gruvbox";
              component_separators = "|";
              section_separators = "";
            };
          };
        };
        
        # Git integration
        gitsigns = {
          enable = true;
          settings = {
            signs = {
              add = {text = "+";};
              change = {text = "~";};
              delete = {text = "_";};
              topdelete = {text = "‾";};
              changedelete = {text = "~";};
            };
          };
        };
        
        # Indent guides
        indent-blankline = {
          enable = true;
          settings = {
            indent = {
              char = "│";
            };
            scope = {
              enabled = true;
            };
          };
        };
        
        # Key binding help
        which-key = {
          enable = true;
          settings = {
            delay = 500;
          };
        };
        
        # Auto pairs
        nvim-autopairs = {
          enable = true;
        };
        
        # Comment toggling
        comment = {
          enable = true;
        };
        
        # Obsidian integration (optional)
        obsidian = {
          enable = true;
          settings = {
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
          };
        };
      };

      ###########################################################################
      # Auto Commands
      ###########################################################################
      autoCmd = [
        {
          event = ["TextYankPost"];
          pattern = ["*"];
          callback = {
            __raw = ''
              function()
                vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })
              end
            '';
          };
        }
        {
          event = ["VimLeavePre"];
          pattern = ["*"];
          callback = {
            __raw = ''
              function()
                pcall(vim.cmd, 'wall')
              end
            '';
          };
        }
      ];

      ###########################################################################
      # Extra Configuration
      ###########################################################################
      extraConfigLua = ''
        -- Additional Lua configuration
        vim.opt.fillchars = { eob = " " }
        
        -- Diagnostic configuration
        vim.diagnostic.config({
          virtual_text = true,
          signs = true,
          underline = true,
          update_in_insert = false,
          severity_sort = true,
        })
        
        -- Custom highlighting
        vim.cmd([[
          highlight Normal guibg=NONE ctermbg=NONE
          highlight NonText guibg=NONE ctermbg=NONE
          highlight SignColumn guibg=NONE ctermbg=NONE
          highlight EndOfBuffer guibg=NONE ctermbg=NONE
        ]])
      '';
    };
  };
}