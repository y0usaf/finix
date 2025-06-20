###############################################################################
# Enhanced Neovim Configuration with MNW (Minimal Neovim Wrapper)
# Modern, declarative Neovim setup with hot reloading and Nix integration
###############################################################################
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.home.dev.nvim;
  inherit (config.shared) username;
  
  # LSP servers and development tools
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
    yaml-language-server
    dockerfile-language-server-nodejs
    
    # Formatters
    stylua
    alejandra
    black
    prettier
    rustfmt
  ];
in {
  ###########################################################################
  # Module Options
  ###########################################################################
  options.home.dev.nvim = {
    enable = lib.mkEnableOption "Enhanced Neovim with MNW wrapper";
    neovide = lib.mkEnableOption "Neovide GUI for Neovim";
  };

  ###########################################################################
  # Module Configuration
  ###########################################################################
  config = lib.mkIf cfg.enable {
    # Import mnw NixOS module
    imports = [ inputs.mnw.nixosModules.default ];
    
    programs.mnw = {
      enable = true;
      appName = "nvim";
      
      # Main Lua configuration
      initLua = ''
        -- ============================================================================
        -- Enhanced Neovim Configuration with MNW
        -- Modern, feature-rich setup with hot reloading capabilities
        -- ============================================================================

        -- Set leader keys early
        vim.g.mapleader = " "
        vim.g.maplocalleader = "\\"

        -- Disable builtin plugins
        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1
        vim.g.loaded_matchparen = 1

        -- ============================================================================
        -- OPTIONS
        -- ============================================================================

        local opt = vim.opt

        -- General
        opt.clipboard = "unnamedplus"
        opt.mouse = "a"
        opt.undofile = true
        opt.undolevels = 10000
        opt.backup = false
        opt.writebackup = false
        opt.swapfile = false

        -- UI
        opt.number = true
        opt.relativenumber = true
        opt.signcolumn = "yes:2"
        opt.cursorline = true
        opt.termguicolors = true
        opt.background = "dark"
        opt.conceallevel = 2
        opt.showmode = false
        opt.laststatus = 3
        opt.showtabline = 2
        opt.cmdheight = 0
        opt.pumheight = 10
        opt.pumblend = 10
        opt.winblend = 10

        -- Editing
        opt.expandtab = true
        opt.tabstop = 2
        opt.shiftwidth = 2
        opt.softtabstop = 2
        opt.autoindent = true
        opt.smartindent = true
        opt.wrap = false

        -- Search
        opt.ignorecase = true
        opt.smartcase = true
        opt.hlsearch = true
        opt.incsearch = true
        opt.grepprg = "rg --vimgrep"

        -- Performance
        opt.updatetime = 250
        opt.timeoutlen = 300
        opt.lazyredraw = true
        opt.synmaxcol = 240

        -- Splits
        opt.splitright = true
        opt.splitbelow = true
        opt.scrolloff = 8
        opt.sidescrolloff = 8

        -- Visual
        opt.list = true
        opt.listchars = "tab:→ ,eol:↲,nbsp:␣,trail:•,extends:⟩,precedes:⟨"
        opt.fillchars = "eob: ,fold: ,foldopen:▾,foldsep: ,foldclose:▸"

        -- Completion
        opt.completeopt = "menu,menuone,noselect"

        -- ============================================================================
        -- KEYMAPS
        -- ============================================================================

        local keymap = vim.keymap.set

        -- Better escape
        keymap("i", "jk", "<Esc>", { desc = "Exit insert mode" })

        -- Window navigation
        keymap("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
        keymap("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
        keymap("n", "<C-k>", "<C-w>k", { desc = "Move to top window" })
        keymap("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

        -- Window resizing
        keymap("n", "<C-Up>", ":resize -2<CR>", { desc = "Resize window up" })
        keymap("n", "<C-Down>", ":resize +2<CR>", { desc = "Resize window down" })
        keymap("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Resize window left" })
        keymap("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Resize window right" })

        -- Buffer navigation (handled by bufferline)
        keymap("n", "<leader>bd", ":bdelete<CR>", { desc = "Delete buffer" })

        -- Clear search highlighting
        keymap("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

        -- File explorer
        keymap("n", "<leader>e", ":Neotree toggle<CR>", { desc = "Toggle file explorer" })
        keymap("n", "<leader>ge", ":Neotree git_status<CR>", { desc = "Git explorer" })
        keymap("n", "<leader>be", ":Neotree buffers<CR>", { desc = "Buffer explorer" })

        -- Telescope
        keymap("n", "<leader>ff", ":Telescope find_files<CR>", { desc = "Find files" })
        keymap("n", "<leader>fw", ":Telescope live_grep<CR>", { desc = "Find word" })
        keymap("n", "<leader>fb", ":Telescope buffers<CR>", { desc = "Find buffers" })
        keymap("n", "<leader>fh", ":Telescope help_tags<CR>", { desc = "Find help" })
        keymap("n", "<leader>fr", ":Telescope oldfiles<CR>", { desc = "Find recent files" })

        -- Buffer navigation
        keymap("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev buffer" })
        keymap("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
        keymap("n", "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", { desc = "Toggle pin" })
        keymap("n", "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", { desc = "Delete non-pinned buffers" })
        keymap("n", "<leader>bo", "<Cmd>BufferLineCloseOthers<CR>", { desc = "Delete other buffers" })
        keymap("n", "<leader>br", "<Cmd>BufferLineCloseRight<CR>", { desc = "Delete buffers to the right" })
        keymap("n", "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", { desc = "Delete buffers to the left" })

        -- Git
        keymap("n", "<leader>gg", ":LazyGit<CR>", { desc = "Open LazyGit" })

        -- Trouble
        keymap("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
        keymap("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer Diagnostics (Trouble)" })
        keymap("n", "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", { desc = "Symbols (Trouble)" })
        keymap("n", "<leader>cl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", { desc = "LSP Definitions / references / ... (Trouble)" })
        keymap("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", { desc = "Location List (Trouble)" })
        keymap("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix List (Trouble)" })

        -- Terminal
        keymap("n", "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", { desc = "Terminal (float)" })
        keymap("n", "<leader>th", "<cmd>ToggleTerm direction=horizontal<cr>", { desc = "Terminal (horizontal)" })
        keymap("n", "<leader>tv", "<cmd>ToggleTerm direction=vertical size=80<cr>", { desc = "Terminal (vertical)" })

        -- Formatting
        keymap("n", "<leader>mp", function() require("conform").format({ lsp_fallback = true }) end, { desc = "Format document" })

        -- Session management
        keymap("n", "<leader>qs", function() require("persistence").load() end, { desc = "Restore Session" })
        keymap("n", "<leader>ql", function() require("persistence").load({ last = true }) end, { desc = "Restore Last Session" })
        keymap("n", "<leader>qd", function() require("persistence").stop() end, { desc = "Don't Save Current Session" })

        -- ============================================================================
        -- PLUGIN SETUP (Nix-managed plugins)
        -- ============================================================================

        -- Catppuccin colorscheme
        require("catppuccin").setup({
          flavour = "mocha",
          background = {
            light = "latte",
            dark = "mocha",
          },
          transparent_background = true,
          show_end_of_buffer = false,
          term_colors = false,
          dim_inactive = {
            enabled = false,
            shade = "dark",
            percentage = 0.15,
          },
          no_italic = false,
          no_bold = false,
          no_underline = false,
          styles = {
            comments = { "italic" },
            conditionals = { "italic" },
            loops = {},
            functions = {},
            keywords = {},
            strings = {},
            variables = {},
            numbers = {},
            booleans = {},
            properties = {},
            types = {},
            operators = {},
          },
          color_overrides = {},
          custom_highlights = {},
          integrations = {
            cmp = true,
            gitsigns = true,
            nvimtree = true,
            treesitter = true,
            notify = false,
            mini = {
              enabled = true,
              indentscope_color = "",
            },
            telescope = {
              enabled = true,
            },
            lsp_trouble = false,
            which_key = true,
          },
        })
        vim.cmd.colorscheme "catppuccin"

        -- LSP setup
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
                checkOnSave = { command = "clippy" },
              },
            },
          },
          ts_ls = {},
          html = {},
          cssls = {},
          jsonls = {},
          bashls = {},
          marksman = {},
          yamlls = {},
          dockerls = {},
        }

        for server, config in pairs(servers) do
          config.capabilities = capabilities
          lspconfig[server].setup(config)
        end

        -- LSP keymaps
        vim.api.nvim_create_autocmd('LspAttach', {
          callback = function(event)
            local opts = { buffer = event.buf }
            keymap("n", "gd", ":Telescope lsp_definitions<CR>", opts)
            keymap("n", "gr", ":Telescope lsp_references<CR>", opts)
            keymap("n", "gi", ":Telescope lsp_implementations<CR>", opts)
            keymap("n", "gt", ":Telescope lsp_type_definitions<CR>", opts)
            keymap("n", "K", vim.lsp.buf.hover, opts)
            keymap("n", "<leader>ca", vim.lsp.buf.code_action, opts)
            keymap("n", "<leader>rn", vim.lsp.buf.rename, opts)
            keymap("n", "<leader>d", vim.diagnostic.open_float, opts)
            keymap("n", "[d", vim.diagnostic.goto_prev, opts)
            keymap("n", "]d", vim.diagnostic.goto_next, opts)
          end,
        })

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

        -- Other plugin configurations
        require("bufferline").setup({
          options = {
            mode = "buffers",
            themable = true,
            numbers = "none",
            close_command = "bdelete! %d",
            right_mouse_command = "bdelete! %d",
            left_mouse_command = "buffer %d",
            middle_mouse_command = nil,
            indicator = {
              icon = "▎",
              style = "icon",
            },
            buffer_close_icon = "",
            modified_icon = "●",
            close_icon = "",
            left_trunc_marker = "",
            right_trunc_marker = "",
            max_name_length = 30,
            max_prefix_length = 30,
            tab_size = 21,
            diagnostics = "nvim_lsp",
            diagnostics_update_in_insert = false,
            offsets = {
              {
                filetype = "neo-tree",
                text = "Neo-tree",
                text_align = "left",
                separator = true,
              },
            },
            color_icons = true,
            show_buffer_icons = true,
            show_buffer_close_icons = true,
            show_close_icon = true,
            show_tab_indicators = true,
            persist_buffer_sort = true,
            separator_style = "thin",
            enforce_regular_tabs = true,
            always_show_bufferline = true,
            hover = {
              enabled = true,
              delay = 200,
              reveal = {'close'},
            },
            sort_by = "insert_after_current",
          },
        })

        require("ibl").setup({
          indent = {
            char = "│",
            tab_char = "│",
          },
          scope = { enabled = false },
          exclude = {
            filetypes = {
              "help",
              "alpha",
              "dashboard",
              "neo-tree",
              "Trouble",
              "trouble",
              "lazy",
              "mason",
              "notify",
              "toggleterm",
              "lazyterm",
            },
          },
        })

        require("mini.indentscope").setup({
          symbol = "│",
          options = { try_as_border = true },
        })

        require('neo-tree').setup({
          close_if_last_window = false,
          popup_border_style = "rounded",
          enable_git_status = true,
          enable_diagnostics = true,
          enable_normal_mode_for_inputs = false,
          open_files_do_not_replace_types = { "terminal", "trouble", "qf" },
          sort_case_insensitive = false,
          sort_function = nil,
          default_component_configs = {
            container = {
              enable_character_fade = true
            },
            indent = {
              indent_size = 2,
              padding = 1,
              with_markers = true,
              indent_marker = "│",
              last_indent_marker = "└",
              highlight = "NeoTreeIndentMarker",
              with_expanders = nil,
              expander_collapsed = "",
              expander_expanded = "",
              expander_highlight = "NeoTreeExpander",
            },
            icon = {
              folder_closed = "",
              folder_open = "",
              folder_empty = "ﰊ",
              default = "*",
              highlight = "NeoTreeFileIcon"
            },
            modified = {
              symbol = "[+]",
              highlight = "NeoTreeModified",
            },
            name = {
              trailing_slash = false,
              use_git_status_colors = true,
              highlight = "NeoTreeFileName",
            },
            git_status = {
              symbols = {
                added     = "",
                modified  = "",
                deleted   = "✖",
                renamed   = "",
                untracked = "",
                ignored   = "",
                unstaged  = "",
                staged    = "",
                conflict  = "",
              }
            },
          },
          window = {
            position = "left",
            width = 40,
            mapping_options = {
              noremap = true,
              nowait = true,
            },
            mappings = {
              ["<space>"] = {
                "toggle_node",
                nowait = false,
              },
              ["<2-LeftMouse>"] = "open",
              ["<cr>"] = "open",
              ["<esc>"] = "revert_preview",
              ["P"] = { "toggle_preview", config = { use_float = true } },
              ["l"] = "focus_preview",
              ["S"] = "open_split",
              ["s"] = "open_vsplit",
              ["t"] = "open_tabnew",
              ["w"] = "open_with_window_picker",
              ["C"] = "close_node",
              ["z"] = "close_all_nodes",
              ["a"] = {
                "add",
                config = {
                  show_path = "none"
                }
              },
              ["A"] = "add_directory",
              ["d"] = "delete",
              ["r"] = "rename",
              ["y"] = "copy_to_clipboard",
              ["x"] = "cut_to_clipboard",
              ["p"] = "paste_from_clipboard",
              ["c"] = "copy",
              ["m"] = "move",
              ["q"] = "close_window",
              ["R"] = "refresh",
              ["?"] = "show_help",
              ["<"] = "prev_source",
              [">"] = "next_source",
            }
          },
          nesting_rules = {},
          filesystem = {
            filtered_items = {
              visible = false,
              hide_dotfiles = true,
              hide_gitignored = true,
              hide_hidden = true,
              hide_by_name = {
                "node_modules"
              },
              hide_by_pattern = {
                "*.meta",
                "*/src/*/tsconfig.json",
              },
              always_show = {
                ".gitignored"
              },
              never_show = {
                ".DS_Store",
                "thumbs.db"
              },
              never_show_by_pattern = {
                ".null-ls_*",
              },
            },
            follow_current_file = {
              enabled = true,
              leave_dirs_open = false,
            },
            group_empty_dirs = false,
            hijack_netrw_behavior = "open_default",
            use_libuv_file_watcher = true,
            window = {
              mappings = {
                ["<bs>"] = "navigate_up",
                ["."] = "set_root",
                ["H"] = "toggle_hidden",
                ["/"] = "fuzzy_finder",
                ["D"] = "fuzzy_finder_directory",
                ["#"] = "fuzzy_sorter",
                ["f"] = "filter_on_submit",
                ["<c-x>"] = "clear_filter",
                ["[g"] = "prev_git_modified",
                ["]g"] = "next_git_modified",
              }
            }
          },
          buffers = {
            follow_current_file = {
              enabled = true,
              leave_dirs_open = false,
            },
            group_empty_dirs = true,
            show_unloaded = true,
            window = {
              mappings = {
                ["bd"] = "buffer_delete",
                ["<bs>"] = "navigate_up",
                ["."] = "set_root",
              }
            },
          },
          git_status = {
            window = {
              position = "float",
              mappings = {
                ["A"]  = "git_add_all",
                ["gu"] = "git_unstage_file",
                ["ga"] = "git_add_file",
                ["gr"] = "git_revert_file",
                ["gc"] = "git_commit",
                ["gp"] = "git_push",
                ["gg"] = "git_commit_and_push",
              }
            }
          }
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
            section_separators = { left = '\ue0b0', right = '\ue0b2' },
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

        require('which-key').setup({
          plugins = {
            spelling = { enabled = true, suggestions = 20 },
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
            yaml = { "prettier" },
            markdown = { "prettier" },
          },
          format_on_save = {
            timeout_ms = 500,
            lsp_fallback = true,
          },
        })

        require("trouble").setup({
          modes = {
            preview_float = {
              mode = "diagnostics",
              preview = {
                type = "float",
                relative = "editor",
                border = "rounded",
                title = "Preview",
                title_pos = "center",
                position = { 0, -2 },
                size = { width = 0.3, height = 0.3 },
                zindex = 200,
              },
            },
          },
        })

        require("toggleterm").setup({
          size = 20,
          open_mapping = [[<c-\>]],
          hide_numbers = true,
          shade_filetypes = {},
          shade_terminals = true,
          shading_factor = 2,
          start_in_insert = true,
          insert_mappings = true,
          persist_size = true,
          direction = "float",
          close_on_exit = true,
          shell = vim.o.shell,
          float_opts = {
            border = "curved",
            winblend = 0,
            highlights = {
              border = "Normal",
              background = "Normal",
            },
          },
        })

        require("persistence").setup()

        -- ============================================================================
        -- DIAGNOSTICS CONFIGURATION
        -- ============================================================================

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

        -- ============================================================================
        -- AUTOCOMMANDS
        -- ============================================================================

        local augroup = vim.api.nvim_create_augroup
        local autocmd = vim.api.nvim_create_autocmd

        -- Highlight on yank
        augroup("YankHighlight", { clear = true })
        autocmd("TextYankPost", {
          group = "YankHighlight",
          callback = function()
            vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
          end,
        })

        -- Remove whitespace on save
        augroup("RemoveWhitespace", { clear = true })
        autocmd("BufWritePre", {
          group = "RemoveWhitespace",
          pattern = "*",
          command = ":%s/\\s\\+$//e",
        })

        -- Close certain windows with q
        augroup("CloseWithQ", { clear = true })
        autocmd("FileType", {
          group = "CloseWithQ",
          pattern = { "help", "startuptime", "qf", "lspinfo" },
          command = "nnoremap <buffer><silent> q :close<CR>",
        })

        -- Auto-resize splits when vim is resized
        augroup("AutoResize", { clear = true })
        autocmd("VimResized", {
          group = "AutoResize",
          command = "tabdo wincmd =",
        })

        -- ============================================================================
        -- TRANSPARENCY AND ADDITIONAL UI TWEAKS
        -- ============================================================================

        -- Additional transparency settings
        vim.cmd([[
          highlight Normal guibg=NONE ctermbg=NONE
          highlight NonText guibg=NONE ctermbg=NONE
          highlight SignColumn guibg=NONE ctermbg=NONE
          highlight EndOfBuffer guibg=NONE ctermbg=NONE
          highlight NormalFloat guibg=NONE ctermbg=NONE
          highlight FloatBorder guibg=NONE ctermbg=NONE
          highlight NeoTreeNormal guibg=NONE ctermbg=NONE
          highlight NeoTreeNormalNC guibg=NONE ctermbg=NONE
          highlight BufferLineFill guibg=NONE ctermbg=NONE
          highlight StatusLine guibg=NONE ctermbg=NONE
          highlight StatusLineNC guibg=NONE ctermbg=NONE
        ]])

        -- Better fold styling
        vim.cmd([[
          highlight Folded guibg=NONE ctermbg=NONE
          highlight FoldColumn guibg=NONE ctermbg=NONE
        ]])

        -- Enhance cursor line for better visibility
        vim.cmd([[
          highlight CursorLine guibg=#1e1e2e ctermbg=235
          highlight CursorLineNr guifg=#cba6f7 guibg=NONE ctermbg=NONE
        ]])
      '';

      # Nix-managed plugins
      plugins = {
        start = with pkgs.vimPlugins; [
          # Core functionality
          plenary-nvim
          nvim-web-devicons

          # Colorscheme
          catppuccin-nvim

          # LSP and completion
          nvim-lspconfig
          nvim-cmp
          cmp-nvim-lsp
          cmp-buffer
          cmp-path
          luasnip
          cmp_luasnip

          # UI components
          bufferline-nvim
          indent-blankline-nvim
          mini-indentscope
          lualine-nvim
          which-key-nvim

          # File navigation
          neo-tree-nvim
          nui-nvim
          telescope-nvim
          telescope-fzf-native-nvim

          # Syntax and editing
          nvim-treesitter.withAllGrammars
          nvim-autopairs
          comment-nvim

          # Git integration
          gitsigns-nvim
          lazygit-nvim

          # Formatting
          conform-nvim

          # Diagnostics
          trouble-nvim

          # Terminal
          toggleterm-nvim

          # Session management
          persistence-nvim
        ];

        # Development plugins for hot reloading
        dev = {
          # You can add custom config here for hot reloading
          # myconfig = {
          #   pure = ./lua/myconfig;
          #   impure = "/home/${username}/.config/nvim/lua/myconfig";
          # };
        };
      };

      # Extra packages in PATH
      extraBinPath = with pkgs; [
        # Enhanced terminal tools for Neovim workflow
        lazygit
        ripgrep
        fd
        tree-sitter
        fzf
        bat
        delta
      ] ++ lspPackages;

      # Provider configuration
      providers = {
        python3 = {
          enable = true;
          extraPackages = ps: with ps; [ pynvim ];
        };
        nodejs = {
          enable = true;
        };
        ruby = {
          enable = true;
        };
        perl = {
          enable = true;
        };
      };

      # Desktop integration
      desktopEntry = true;

      # Aliases
      aliases = [ "vi" "vim" ];
    };

    # Install neovide if enabled
    users.users.${username}.maid.packages = lib.optionals cfg.neovide [
      pkgs.neovide
    ];
  };
}