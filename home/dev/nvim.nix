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
        # Enhanced terminal tools for Neovim workflow
        lazygit
        ripgrep
        fd
        tree-sitter
      ] ++ lib.optionals cfg.neovide [
        neovide
      ];
    };
    
    ###########################################################################
    # Enhanced NixVim Configuration
    ###########################################################################
    programs.nixvim = {
      enable = true;
      defaultEditor = true;
      
      ###########################################################################
      # Performance & Startup
      ###########################################################################
      globals = {
        mapleader = " ";  # Space as leader key (more ergonomic)
        maplocalleader = "\\";
        
        # Performance improvements
        loaded_netrw = 1;
        loaded_netrwPlugin = 1;
        loaded_matchparen = 1;
      };
      
      ###########################################################################
      # Enhanced Options
      ###########################################################################
      opts = {
        # Editor behavior
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
        
        # Search improvements
        ignorecase = true;
        smartcase = true;
        hlsearch = true;
        incsearch = true;
        grepprg = "rg --vimgrep";
        
        # Interface enhancements
        signcolumn = "yes:2";  # Always show signcolumn with 2 spaces
        updatetime = 250;  # Faster updates
        timeoutlen = 300;  # Faster which-key
        cmdheight = 0;  # Hide command line when not used
        laststatus = 3;  # Global statusline
        showtabline = 2;  # Always show tabline
        pumheight = 10;  # Popup menu height
        pumblend = 10;  # Popup transparency
        winblend = 10;  # Window transparency
        completeopt = ["menu" "menuone" "noselect"];
        
        # File handling
        backup = false;
        writebackup = false;
        swapfile = false;
        undofile = true;
        undolevels = 10000;
        
        # Split behavior
        splitright = true;
        splitbelow = true;
        
        # Scroll behavior
        scrolloff = 8;
        sidescrolloff = 8;
        
        # Performance
        lazyredraw = true;
        synmaxcol = 240;
        
        # Visual enhancements
        cursorline = true;
        showmode = false;  # Mode shown in lualine
        list = true;
        listchars = "tab:→ ,eol:↲,nbsp:␣,trail:•,extends:⟩,precedes:⟨";
        fillchars = "eob: ,fold: ,foldopen:▾,foldsep: ,foldclose:▸";
      };

      ###########################################################################
      # Clean Transparent Theme
      ###########################################################################
      # No colorscheme - inherit from terminal with transparency

      ###########################################################################
      # Enhanced Key Mappings
      ###########################################################################
      keymaps = [
        # Better escape
        { mode = "i"; key = "jk"; action = "<Esc>"; options.desc = "Exit insert mode"; }
        
        # Better window navigation
        { mode = "n"; key = "<C-h>"; action = "<C-w>h"; options.desc = "Move to left window"; }
        { mode = "n"; key = "<C-j>"; action = "<C-w>j"; options.desc = "Move to bottom window"; }
        { mode = "n"; key = "<C-k>"; action = "<C-w>k"; options.desc = "Move to top window"; }
        { mode = "n"; key = "<C-l>"; action = "<C-w>l"; options.desc = "Move to right window"; }
        
        # Better window resizing
        { mode = "n"; key = "<C-Up>"; action = ":resize +2<CR>"; options.desc = "Increase window height"; }
        { mode = "n"; key = "<C-Down>"; action = ":resize -2<CR>"; options.desc = "Decrease window height"; }
        { mode = "n"; key = "<C-Left>"; action = ":vertical resize -2<CR>"; options.desc = "Decrease window width"; }
        { mode = "n"; key = "<C-Right>"; action = ":vertical resize +2<CR>"; options.desc = "Increase window width"; }
        
        # Better indenting
        { mode = "v"; key = "<"; action = "<gv"; options.desc = "Indent left"; }
        { mode = "v"; key = ">"; action = ">gv"; options.desc = "Indent right"; }
        
        # Move lines up/down
        { mode = "v"; key = "J"; action = ":m '>+1<CR>gv=gv"; options.desc = "Move selection down"; }
        { mode = "v"; key = "K"; action = ":m '<-2<CR>gv=gv"; options.desc = "Move selection up"; }
        
        # Better search
        { mode = "n"; key = "n"; action = "nzzzv"; options.desc = "Next search result"; }
        { mode = "n"; key = "N"; action = "Nzzzv"; options.desc = "Previous search result"; }
        { mode = "n"; key = "<Esc>"; action = ":noh<CR>"; options.desc = "Clear search highlight"; }
        
        # File explorer (Neo-tree)
        { mode = "n"; key = "<leader>e"; action = ":Neotree toggle<CR>"; options.desc = "Toggle file explorer"; }
        { mode = "n"; key = "<leader>o"; action = ":Neotree focus<CR>"; options.desc = "Focus file explorer"; }
        
        # Telescope - Enhanced
        { mode = "n"; key = "<leader>ff"; action = ":Telescope find_files<CR>"; options.desc = "Find files"; }
        { mode = "n"; key = "<leader>fw"; action = ":Telescope live_grep<CR>"; options.desc = "Find word"; }
        { mode = "n"; key = "<leader>fb"; action = ":Telescope buffers<CR>"; options.desc = "Find buffers"; }
        { mode = "n"; key = "<leader>fh"; action = ":Telescope help_tags<CR>"; options.desc = "Find help"; }
        { mode = "n"; key = "<leader>fr"; action = ":Telescope oldfiles<CR>"; options.desc = "Recent files"; }
        { mode = "n"; key = "<leader>fc"; action = ":Telescope commands<CR>"; options.desc = "Commands"; }
        { mode = "n"; key = "<leader>fk"; action = ":Telescope keymaps<CR>"; options.desc = "Keymaps"; }
        
        # LSP Enhanced
        { mode = "n"; key = "gd"; action = ":Telescope lsp_definitions<CR>"; options.desc = "Go to definition"; }
        { mode = "n"; key = "gr"; action = ":Telescope lsp_references<CR>"; options.desc = "Go to references"; }
        { mode = "n"; key = "gi"; action = ":Telescope lsp_implementations<CR>"; options.desc = "Go to implementation"; }
        { mode = "n"; key = "gt"; action = ":Telescope lsp_type_definitions<CR>"; options.desc = "Go to type definition"; }
        { mode = "n"; key = "K"; action = "<cmd>lua vim.lsp.buf.hover()<CR>"; options.desc = "Hover documentation"; }
        { mode = "n"; key = "<leader>ca"; action = "<cmd>lua vim.lsp.buf.code_action()<CR>"; options.desc = "Code actions"; }
        { mode = "n"; key = "<leader>rn"; action = "<cmd>lua vim.lsp.buf.rename()<CR>"; options.desc = "Rename symbol"; }
        { mode = "n"; key = "<leader>d"; action = ":Telescope diagnostics<CR>"; options.desc = "Show diagnostics"; }
        { mode = "n"; key = "[d"; action = "<cmd>lua vim.diagnostic.goto_prev()<CR>"; options.desc = "Previous diagnostic"; }
        { mode = "n"; key = "]d"; action = "<cmd>lua vim.diagnostic.goto_next()<CR>"; options.desc = "Next diagnostic"; }
        
        # Formatting
        { mode = ["n" "v"]; key = "<leader>f"; action = "<cmd>lua require('conform').format()<CR>"; options.desc = "Format code"; }
        
        # Terminal
        { mode = "n"; key = "<leader>t"; action = ":ToggleTerm<CR>"; options.desc = "Toggle terminal"; }
        { mode = "t"; key = "<Esc>"; action = "<C-\\><C-n>"; options.desc = "Exit terminal mode"; }
        
        # Git
        { mode = "n"; key = "<leader>gg"; action = ":LazyGit<CR>"; options.desc = "LazyGit"; }
        { mode = "n"; key = "<leader>gb"; action = ":Telescope git_branches<CR>"; options.desc = "Git branches"; }
        { mode = "n"; key = "<leader>gc"; action = ":Telescope git_commits<CR>"; options.desc = "Git commits"; }
        { mode = "n"; key = "<leader>gs"; action = ":Telescope git_status<CR>"; options.desc = "Git status"; }
        
        # Buffer management
        { mode = "n"; key = "<S-h>"; action = ":bprevious<CR>"; options.desc = "Previous buffer"; }
        { mode = "n"; key = "<S-l>"; action = ":bnext<CR>"; options.desc = "Next buffer"; }
        { mode = "n"; key = "<leader>bd"; action = ":bdelete<CR>"; options.desc = "Delete buffer"; }
        
        # Trouble (diagnostics)
        { mode = "n"; key = "<leader>xx"; action = ":Trouble diagnostics toggle<CR>"; options.desc = "Toggle diagnostics"; }
        { mode = "n"; key = "<leader>xw"; action = ":Trouble workspace_diagnostics<CR>"; options.desc = "Workspace diagnostics"; }
        { mode = "n"; key = "<leader>xd"; action = ":Trouble document_diagnostics<CR>"; options.desc = "Document diagnostics"; }
        { mode = "n"; key = "<leader>xq"; action = ":Trouble quickfix<CR>"; options.desc = "Quickfix list"; }
        { mode = "n"; key = "<leader>xl"; action = ":Trouble loclist<CR>"; options.desc = "Location list"; }
        
        # Sessions
        { mode = "n"; key = "<leader>ss"; action = ":SessionSave<CR>"; options.desc = "Save session"; }
        { mode = "n"; key = "<leader>sr"; action = ":SessionRestore<CR>"; options.desc = "Restore session"; }
      ];

      ###########################################################################
      # Enhanced Plugins Configuration
      ###########################################################################
      plugins = {
        # Web devicons (explicitly enabled)
        web-devicons.enable = true;
        
        # Enhanced LSP with better UI
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
            marksman.enable = true;  # Markdown LSP
          };
        };
        
        # Enhanced completion with snippets
        cmp = {
          enable = true;
          settings = {
            snippet = {
              expand = "function(args) require('luasnip').lsp_expand(args.body) end";
            };
            sources = [
              { name = "nvim_lsp"; priority = 1000; }
              { name = "luasnip"; priority = 750; }
              { name = "buffer"; priority = 500; }
              { name = "path"; priority = 250; }
              { name = "cmdline"; priority = 300; }
            ];
            mapping = {
              "<C-Space>" = "cmp.mapping.complete()";
              "<C-e>" = "cmp.mapping.abort()";
              "<CR>" = "cmp.mapping.confirm({ select = true })";
              "<Tab>" = "cmp.mapping(function(fallback) if cmp.visible() then cmp.select_next_item() elseif require('luasnip').expand_or_jumpable() then require('luasnip').expand_or_jump() else fallback() end end, {'i', 's'})";
              "<S-Tab>" = "cmp.mapping(function(fallback) if cmp.visible() then cmp.select_prev_item() elseif require('luasnip').jumpable(-1) then require('luasnip').jump(-1) else fallback() end end, {'i', 's'})";
              "<C-j>" = "cmp.mapping.select_next_item()";
              "<C-k>" = "cmp.mapping.select_prev_item()";
              "<C-d>" = "cmp.mapping.scroll_docs(4)";
              "<C-u>" = "cmp.mapping.scroll_docs(-4)";
            };
            formatting = {
              fields = ["kind" "abbr" "menu"];
            };
            window = {
              completion = {
                border = "rounded";
                winhighlight = "Normal:CmpPmenu,CursorLine:CmpSel,Search:None";
              };
              documentation = {
                border = "rounded";
              };
            };
            experimental = {
              ghost_text = true;
            };
          };
        };
        
        # Snippets
        luasnip = {
          enable = true;
          settings = {
            enable_autosnippets = true;
            store_selection_keys = "<Tab>";
          };
        };
        
        # Modern file explorer - Neo-tree
        neo-tree = {
          enable = true;
          closeIfLastWindow = true;
          popupBorderStyle = "rounded";
          enableGitStatus = true;
          enableModifiedMarkers = true;
          enableRefreshOnWrite = true;
          defaultComponentConfigs = {
            gitStatus = {
              symbols = {
                added = " ";
                deleted = " ";
                modified = " ";
                renamed = "➜";
                untracked = "★";
                ignored = "◌";
                unstaged = "✗";
                staged = "✓";
                conflict = "";
              };
            };
          };
          window = {
            width = 35;
            mappings = {
              "<space>" = "toggle_node";
              "<2-LeftMouse>" = "open";
              "<CR>" = "open";
              "o" = "open";
              "S" = "open_split";
              "s" = "open_vsplit";
              "t" = "open_tabnew";
              "C" = "close_node";
              "z" = "close_all_nodes";
              "R" = "refresh";
              "a" = "add";
              "A" = "add_directory";
              "d" = "delete";
              "r" = "rename";
              "c" = "copy";
              "m" = "move";
              "q" = "close_window";
            };
          };
          filesystem = {
            followCurrentFile = {
              enabled = true;
            };
            useLibuvFileWatcher = true;
            filteredItems = {
              hideDotfiles = false;
              hideGitignored = false;
              hideByName = [
                "node_modules"
                ".git"
                ".DS_Store"
                "thumbs.db"
              ];
            };
          };
        };
        
        # Enhanced Telescope
        telescope = {
          enable = true;
          settings = {
            defaults = {
              prompt_prefix = " ";
              selection_caret = " ";
              path_display = ["truncate"];
              file_ignore_patterns = [
                "^.git/"
                "^.mypy_cache/"
                "^__pycache__/"
                "^output/"
                "^data/"
                "%.ipynb"
                "node_modules"
              ];
              layout_config = {
                horizontal = {
                  prompt_position = "top";
                  preview_width = 0.55;
                  results_width = 0.8;
                };
                vertical = {
                  mirror = false;
                };
                width = 0.87;
                height = 0.80;
                preview_cutoff = 120;
              };
              sorting_strategy = "ascending";
              winblend = 0;
              border = true;
              borderchars = ["─" "│" "─" "│" "╭" "╮" "╯" "╰"];
              color_devicons = true;
              use_less = true;
              set_env.COLORTERM = "truecolor";
            };
          };
          extensions = {
            fzf-native = {
              enable = true;
              settings = {
                fuzzy = true;
                override_generic_sorter = true;
                override_file_sorter = true;
                case_mode = "smart_case";
              };
            };
          };
        };
        
        # Enhanced Treesitter
        treesitter = {
          enable = true;
          settings = {
            highlight = {
              enable = true;
              additional_vim_regex_highlighting = false;
            };
            indent = { enable = true; };
            incremental_selection = {
              enable = true;
              keymaps = {
                init_selection = "<C-space>";
                node_incremental = "<C-space>";
                scope_incremental = false;
                node_decremental = "<bs>";
              };
            };
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
              "markdown_inline"
              "regex"
              "vim"
              "vimdoc"
            ];
          };
        };
        
        # Enhanced status line
        lualine = {
          enable = true;
          settings = {
            options = {
              theme = "auto";  # Inherit from terminal
              component_separators = { left = ""; right = ""; };
              section_separators = { left = ""; right = ""; };
              globalstatus = true;
              refresh.statusline = 1000;
            };
            sections = {
              lualine_a = ["mode"];
              lualine_b = [
                {
                  __unkeyed-1 = "branch";
                  icon = "";
                }
                "diff"
                "diagnostics"
              ];
              lualine_c = [
                {
                  __unkeyed-1 = "filename";
                  file_status = true;
                  newfile_status = false;
                  path = 1;
                  symbols = {
                    modified = " ";
                    readonly = " ";
                    unnamed = "[No Name]";
                    newfile = " ";
                  };
                }
              ];
              lualine_x = [
                "encoding"
                "fileformat"
                "filetype"
              ];
              lualine_y = ["progress"];
              lualine_z = ["location"];
            };
          };
        };
        
        # Buffer line (tabs)
        bufferline = {
          enable = true;
          settings = {
            options = {
              mode = "buffers";
              separator_style = "slant";
              always_show_bufferline = true;
              show_buffer_close_icons = false;
              show_close_icon = false;
              color_icons = true;
              diagnostics = "nvim_lsp";
              diagnostics_indicator = ''
                function(count, level, diagnostics_dict, context)
                  local s = " "
                  for e, n in pairs(diagnostics_dict) do
                    local sym = e == "error" and " " or (e == "warning" and " " or "")
                    s = s .. n .. sym
                  end
                  return s
                end
              '';
            };
          };
        };
        
        # Enhanced Git integration
        gitsigns = {
          enable = true;
          settings = {
            signs = {
              add = { text = "│"; };
              change = { text = "│"; };
              delete = { text = "_"; };
              topdelete = { text = "‾"; };
              changedelete = { text = "~"; };
              untracked = { text = "┆"; };
            };
            signcolumn = true;
            numhl = false;
            linehl = false;
            word_diff = false;
            watch_gitdir = {
              follow_files = true;
            };
            attach_to_untracked = true;
            current_line_blame = false;
            current_line_blame_opts = {
              virt_text = true;
              virt_text_pos = "eol";
              delay = 1000;
              ignore_whitespace = false;
            };
            sign_priority = 6;
            update_debounce = 100;
            status_formatter = null;
            max_file_length = 40000;
            preview_config = {
              border = "single";
              style = "minimal";
              relative = "cursor";
              row = 0;
              col = 1;
            };
          };
        };
        
        # Enhanced indent guides
        indent-blankline = {
          enable = true;
          settings = {
            indent = {
              char = "│";
              tab_char = "│";
            };
            scope = {
              enabled = true;
              show_start = true;
              show_end = false;
            };
            exclude = {
              filetypes = [
                "help"
                "alpha"
                "dashboard"
                "neo-tree"
                "Trouble"
                "trouble"
                "lazy"
                "mason"
                "notify"
                "toggleterm"
                "lazyterm"
              ];
            };
          };
        };
        
        # Enhanced which-key
        which-key = {
          enable = true;
          settings = {
            delay = 200;
            expand = 1;
            notify = false;
            preset = "modern";
            spec = [
              { __unkeyed-1 = "<leader>f"; group = "Find"; }
              { __unkeyed-1 = "<leader>g"; group = "Git"; }
              { __unkeyed-1 = "<leader>x"; group = "Diagnostics"; }
              { __unkeyed-1 = "<leader>s"; group = "Session"; }
              { __unkeyed-1 = "<leader>b"; group = "Buffer"; }
              { __unkeyed-1 = "<leader>c"; group = "Code"; }
              { __unkeyed-1 = "<leader>t"; group = "Terminal"; }
            ];
          };
        };
        
        # Auto pairs
        nvim-autopairs = {
          enable = true;
          settings = {
            check_ts = true;
            ts_config = {
              lua = ["string" "source"];
              javascript = ["string" "template_string"];
              java = false;
            };
            disable_filetype = ["TelescopePrompt" "vim"];
          };
        };
        
        # Enhanced comment
        comment = {
          enable = true;
          settings = {
            toggler = {
              line = "gcc";
              block = "gbc";
            };
            opleader = {
              line = "gc";
              block = "gb";
            };
            extra = {
              above = "gcO";
              below = "gco";
              eol = "gcA";
            };
            mappings = {
              basic = true;
              extra = true;
            };
          };
        };
        
        # Terminal integration
        toggleterm = {
          enable = true;
          settings = {
            size = 20;
            open_mapping = "[[<c-\\>]]";
            hide_numbers = true;
            shade_terminals = true;
            shading_factor = 2;
            start_in_insert = true;
            insert_mappings = true;
            persist_size = true;
            direction = "float";
            close_on_exit = true;
            shell = "zsh";
            auto_scroll = true;
            float_opts = {
              border = "curved";
              winblend = 0;
              highlights = {
                border = "Normal";
                background = "Normal";
              };
            };
          };
        };
        
        # LazyGit integration
        lazygit = {
          enable = true;
        };
        
        # Diagnostics UI
        trouble = {
          enable = true;
          settings = {
            auto_jump = false;
            auto_close = false;
            auto_open = false;
            auto_preview = true;
            focus = false;
            restore = true;
            follow = true;
            indent_guides = true;
            max_items = 200;
            multiline = true;
            pinned = false;
            warn_no_results = true;
            open_no_results = false;
          };
        };
        
        # Session management
        auto-session = {
          enable = true;
          settings = {
            log_level = "error";
            auto_session_enable_last_session = false;
            auto_session_root_dir = "~/.local/share/nvim/sessions/";
            auto_session_enabled = true;
            auto_save_enabled = null;
            auto_restore_enabled = null;
            auto_session_suppress_dirs = ["~/" "~/Downloads" "/tmp"];
            auto_session_use_git_branch = false;
          };
        };
        
        # Code formatting
        conform-nvim = {
          enable = true;
          settings = {
            formatters_by_ft = {
              lua = ["stylua"];
              nix = ["alejandra"];
              python = ["black"];
              javascript = ["prettier"];
              typescript = ["prettier"];
              html = ["prettier"];
              css = ["prettier"];
              json = ["prettier"];
              yaml = ["prettier"];
              markdown = ["prettier"];
              rust = ["rustfmt"];
            };
            format_on_save = {
              timeout_ms = 500;
              lsp_fallback = true;
            };
          };
        };
        
        # Notifications
        notify = {
          enable = true;
          settings = {
            background_colour = "#000000";
            fps = 30;
            render = "default";
            timeout = 500;
            top_down = true;
          };
        };
        
        # Smooth scrolling
        neoscroll = {
          enable = true;
          settings = {
            mappings = ["<C-u>" "<C-d>" "<C-b>" "<C-f>" "<C-y>" "<C-e>" "zt" "zz" "zb"];
            hide_cursor = true;
            stop_eof = true;
            respect_scrolloff = false;
            cursor_scrolls_alone = true;
            easing_function = null;
            pre_hook = null;
            post_hook = null;
            performance_mode = false;
          };
        };
        
        # Surround text objects
        nvim-surround = {
          enable = true;
          settings = {
            keymaps = {
              insert = "<C-g>s";
              insert_line = "<C-g>S";
              normal = "ys";
              normal_cur = "yss";
              normal_line = "yS";
              normal_cur_line = "ySS";
              visual = "S";
              visual_line = "gS";
              delete = "ds";
              change = "cs";
            };
          };
        };
        
        # Dashboard
        alpha = {
          enable = true;
          layout = [
            {
              type = "padding";
              val = 2;
            }
            {
              type = "text";
              val = [
                "███╗   ██╗██╗██╗  ██╗██╗   ██╗██╗███╗   ███╗"
                "████╗  ██║██║╚██╗██╔╝██║   ██║██║████╗ ████║"
                "██╔██╗ ██║██║ ╚███╔╝ ██║   ██║██║██╔████╔██║"
                "██║╚██╗██║██║ ██╔██╗ ╚██╗ ██╔╝██║██║╚██╔╝██║"
                "██║ ╚████║██║██╔╝ ██╗ ╚████╔╝ ██║██║ ╚═╝ ██║"
                "╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝  ╚═══╝  ╚═╝╚═╝     ╚═╝"
              ];
              opts = {
                position = "center";
                hl = "Type";
              };
            }
            {
              type = "padding";
              val = 2;
            }
            {
              type = "group";
              val = [
                {
                  type = "button";
                  val = "  Find file";
                  on_press = {
                    __raw = "function() require('telescope.builtin').find_files() end";
                  };
                  opts = {
                    shortcut = "f";
                    position = "center";
                    cursor = 3;
                    width = 38;
                    align_shortcut = "right";
                    hl_shortcut = "Keyword";
                  };
                }
                {
                  type = "button";
                  val = "  New file";
                  on_press = {
                    __raw = "function() vim.cmd[[ene]] end";
                  };
                  opts = {
                    shortcut = "n";
                    position = "center";
                    cursor = 3;
                    width = 38;
                    align_shortcut = "right";
                    hl_shortcut = "Keyword";
                  };
                }
                {
                  type = "button";
                  val = "  Recent files";
                  on_press = {
                    __raw = "function() require('telescope.builtin').oldfiles() end";
                  };
                  opts = {
                    shortcut = "r";
                    position = "center";
                    cursor = 3;
                    width = 38;
                    align_shortcut = "right";
                    hl_shortcut = "Keyword";
                  };
                }
                {
                  type = "button";
                  val = "  Find text";
                  on_press = {
                    __raw = "function() require('telescope.builtin').live_grep() end";
                  };
                  opts = {
                    shortcut = "g";
                    position = "center";
                    cursor = 3;
                    width = 38;
                    align_shortcut = "right";
                    hl_shortcut = "Keyword";
                  };
                }
                {
                  type = "button";
                  val = "  Config";
                  on_press = {
                    __raw = "function() vim.cmd[[e ~/.config/nixos/home/dev/nvim.nix]] end";
                  };
                  opts = {
                    shortcut = "c";
                    position = "center";
                    cursor = 3;
                    width = 38;
                    align_shortcut = "right";
                    hl_shortcut = "Keyword";
                  };
                }
                {
                  type = "button";
                  val = "  Restore Session";
                  on_press = {
                    __raw = "function() require('auto-session.session-lens').search_session() end";
                  };
                  opts = {
                    shortcut = "s";
                    position = "center";
                    cursor = 3;
                    width = 38;
                    align_shortcut = "right";
                    hl_shortcut = "Keyword";
                  };
                }
                {
                  type = "button";
                  val = "  Lazy";
                  on_press = {
                    __raw = "function() vim.cmd[[Lazy]] end";
                  };
                  opts = {
                    shortcut = "l";
                    position = "center";
                    cursor = 3;
                    width = 38;
                    align_shortcut = "right";
                    hl_shortcut = "Keyword";
                  };
                }
                {
                  type = "button";
                  val = "  Quit";
                  on_press = {
                    __raw = "function() vim.cmd[[qa]] end";
                  };
                  opts = {
                    shortcut = "q";
                    position = "center";
                    cursor = 3;
                    width = 38;
                    align_shortcut = "right";
                    hl_shortcut = "Keyword";
                  };
                }
              ];
            }
            {
              type = "padding";
              val = 2;
            }
          ];
        };
      };

      ###########################################################################
      # Auto Commands
      ###########################################################################
      autoCmd = [
        # Highlight on yank
        {
          event = ["TextYankPost"];
          pattern = ["*"];
          callback = {
            __raw = ''
              function()
                vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
              end
            '';
          };
        }
        
        # Auto-save on focus lost
        {
          event = ["FocusLost"];
          pattern = ["*"];
          callback = {
            __raw = ''
              function()
                if vim.bo.modified and not vim.bo.readonly and vim.fn.expand("%") ~= "" and vim.bo.buftype == "" then
                  vim.cmd('silent update')
                end
              end
            '';
          };
        }
        
        # Remember cursor position
        {
          event = ["BufReadPost"];
          pattern = ["*"];
          callback = {
            __raw = ''
              function()
                local mark = vim.api.nvim_buf_get_mark(0, '"')
                local lcount = vim.api.nvim_buf_line_count(0)
                if mark[1] > 0 and mark[1] <= lcount then
                  pcall(vim.api.nvim_win_set_cursor, 0, mark)
                end
              end
            '';
          };
        }
        
        # Close certain windows with q
        {
          event = ["FileType"];
          pattern = ["qf" "help" "man" "lspinfo" "spectre_panel"];
          callback = {
            __raw = ''
              function()
                vim.cmd [[
                  nnoremap <silent> <buffer> q :close<CR> 
                  set nobuflisted 
                ]]
              end
            '';
          };
        }
        
        # Auto-create directories when saving
        {
          event = ["BufWritePre"];
          pattern = ["*"];
          callback = {
            __raw = ''
              function()
                local dir = vim.fn.expand('<afile>:p:h')
                if vim.fn.isdirectory(dir) == 0 then
                  vim.fn.mkdir(dir, 'p')
                end
              end
            '';
          };
        }
      ];

      ###########################################################################
      # Enhanced Configuration
      ###########################################################################
      extraConfigLua = ''
        -- Enhanced diagnostics configuration
        vim.diagnostic.config({
          virtual_text = {
            enabled = true,
            source = "if_many",
            prefix = "●",
          },
          signs = {
            active = signs,
          },
          update_in_insert = true,
          underline = true,
          severity_sort = true,
          float = {
            focusable = false,
            style = "minimal",
            border = "rounded",
            source = "always",
            header = "",
            prefix = "",
          },
        })
        
        -- Enhanced LSP UI
        local signs = { Error = " ", Warn = " ", Hint = " ", Info = " " }
        for type, icon in pairs(signs) do
          local hl = "DiagnosticSign" .. type
          vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
        end
        
        -- Better hover windows
        vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
          border = "rounded",
        })
        
        vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
          border = "rounded",
        })
        
        -- Enhanced folding
        vim.opt.fillchars = {
          foldopen = "▾",
          foldclose = "▸",
          fold = " ",
          foldsep = " ",
          diff = "╱",
          eob = " ",
        }
        
        -- Auto-save function
        local function auto_save()
          if vim.bo.modified and not vim.bo.readonly and vim.fn.expand("%") ~= "" and vim.bo.buftype == "" then
            vim.cmd('silent update')
          end
        end
        
        -- Auto-save on idle
        vim.api.nvim_create_autocmd("CursorHold", {
          callback = auto_save,
        })
        
        -- Better search highlighting
        vim.cmd([[
          augroup vimrc-incsearch-highlight
            autocmd!
            autocmd CmdlineEnter /,\? :set hlsearch
            autocmd CmdlineLeave /,\? :set nohlsearch
          augroup END
        ]])
        
        -- Terminal settings
        vim.api.nvim_create_autocmd("TermOpen", {
          callback = function()
            vim.opt_local.number = false
            vim.opt_local.relativenumber = false
            vim.opt_local.signcolumn = "no"
          end,
        })
        
        -- Full transparency setup
        vim.cmd([[
          " Make everything transparent
          highlight Normal guibg=NONE ctermbg=NONE
          highlight NonText guibg=NONE ctermbg=NONE
          highlight SignColumn guibg=NONE ctermbg=NONE
          highlight EndOfBuffer guibg=NONE ctermbg=NONE
          highlight StatusLine guibg=NONE ctermbg=NONE
          highlight StatusLineNC guibg=NONE ctermbg=NONE
          highlight VertSplit guibg=NONE ctermbg=NONE
          highlight WinSeparator guibg=NONE ctermbg=NONE
          highlight TabLine guibg=NONE ctermbg=NONE
          highlight TabLineFill guibg=NONE ctermbg=NONE
          highlight TabLineSel guibg=NONE ctermbg=NONE
          
          " Neo-tree transparency
          highlight NeoTreeNormal guibg=NONE ctermbg=NONE
          highlight NeoTreeNormalNC guibg=NONE ctermbg=NONE
          highlight NeoTreeVertSplit guibg=NONE ctermbg=NONE
          highlight NeoTreeWinSeparator guibg=NONE ctermbg=NONE
          highlight NeoTreeEndOfBuffer guibg=NONE ctermbg=NONE
          
          " Telescope transparency
          highlight TelescopeNormal guibg=NONE ctermbg=NONE
          highlight TelescopeBorder guibg=NONE ctermbg=NONE
          highlight TelescopePromptNormal guibg=NONE ctermbg=NONE
          highlight TelescopeResultsNormal guibg=NONE ctermbg=NONE
          highlight TelescopePreviewNormal guibg=NONE ctermbg=NONE
          
          " Popup menus transparency
          highlight Pmenu guibg=NONE ctermbg=NONE
          highlight PmenuSel guibg=NONE ctermbg=NONE
          highlight PmenuSbar guibg=NONE ctermbg=NONE
          highlight PmenuThumb guibg=NONE ctermbg=NONE
          
          " Floating windows transparency
          highlight NormalFloat guibg=NONE ctermbg=NONE
          highlight FloatBorder guibg=NONE ctermbg=NONE
          
          " Diagnostics with subtle styling
          highlight DiagnosticError gui=bold
          highlight DiagnosticWarn gui=bold
          highlight DiagnosticInfo gui=bold
          highlight DiagnosticHint gui=italic
          
          " Make search results stand out
          highlight Search gui=bold,reverse
          highlight IncSearch gui=bold,reverse
          
          " Clean cursor line
          highlight CursorLine gui=underline guibg=NONE ctermbg=NONE
          highlight CursorLineNr gui=bold
          
          " Git signs with subtle colors
          highlight GitSignsAdd gui=bold
          highlight GitSignsChange gui=bold
          highlight GitSignsDelete gui=bold
          
          " Clean which-key
          highlight WhichKey gui=bold
          highlight WhichKeyDesc gui=italic
          highlight WhichKeyGroup gui=bold
          highlight WhichKeySeparator gui=italic
        ]])
      '';
    };
  };
}