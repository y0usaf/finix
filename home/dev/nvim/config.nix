###############################################################################
# Neovim Main Configuration
# Single file that generates modular Lua configuration
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
    lua-language-server nil pyright rust-analyzer typescript-language-server
    vscode-langservers-extracted bash-language-server marksman yaml-language-server
    dockerfile-language-server-nodejs stylua alejandra black prettier rustfmt
  ];

  # Create MNW-based Neovim package using proper module system
  mnwNeovim = inputs.mnw.lib.wrap pkgs {
    neovim = pkgs.neovim-unwrapped;
    initLua = "require('init')";
    
    plugins = {
      start = with pkgs.vimPlugins; [
        # Core functionality
        nvim-lspconfig nvim-cmp cmp-nvim-lsp cmp-buffer cmp-path cmp_luasnip luasnip
        nvim-treesitter.withAllGrammars plenary-nvim nvim-web-devicons lualine-nvim
        indent-blankline-nvim which-key-nvim telescope-nvim telescope-fzf-native-nvim
        neo-tree-nvim bufferline-nvim nui-nvim gitsigns-nvim lazygit-nvim comment-nvim
        nvim-autopairs mini-indentscope conform-nvim trouble-nvim toggleterm-nvim persistence-nvim
        
        # ADHD-friendly enhancements
        alpha-nvim nvim-notify noice-nvim dressing-nvim nvim-colorizer-lua
        zen-mode-nvim twilight-nvim neoscroll-nvim rainbow-delimiters-nvim
        fidget-nvim vim-illuminate todo-comments-nvim nvim-hlslens
      ];
    };
    
    extraBinPath = lspPackages;
  };
in {
  config = lib.mkIf cfg.enable {
    users.users.${username}.maid = {
      packages = [
        pkgs.lazygit pkgs.ripgrep pkgs.fd pkgs.tree-sitter pkgs.fzf pkgs.bat pkgs.delta mnwNeovim
      ];

      # Note: mnw handles all Lua configuration through its module system
      # No need for manual file.xdg_config when using mnw properly
        "nvim/lua/init.lua".text = ''
          vim.g.mapleader = " "
          vim.g.maplocalleader = "\\"
          vim.g.loaded_netrw = 1
          vim.g.loaded_netrwPlugin = 1
          vim.g.loaded_matchparen = 1

          require('config.options')
          require('config.keymaps') 
          require('config.theme')
          require('config.lsp')
          require('config.plugins')
          require('config.autocmds')
          require('config.neovide')
          require('config.adhd-enhancements')
          
          -- HYPER-STIMULATING options for maximum ADHD engagement
          vim.opt.relativenumber = true
          vim.opt.cursorline = true
          vim.opt.cursorcolumn = true  -- Extra visual reference
          vim.opt.showbreak = "↪ "
          vim.opt.listchars = "tab:→ ,eol:↲,nbsp:␣,trail:•,extends:⟩,precedes:⟨,space:·"
          vim.opt.fillchars = "eob:~,fold:━,foldopen:▾,foldsep:│,foldclose:▸,diff:╱,msgsep:━,horiz:━,horizup:┻,horizdown:┳,vert:┃,vertleft:┫,vertright:┣,verthoriz:╋"
        '';

        "nvim/lua/config/adhd-enhancements.lua".text = ''
          -- ADHD-Friendly Neovim Enhancements
          -- Dashboard/Startup Screen
          pcall(function()
            local alpha = require("alpha")
            local dashboard = require("alpha.themes.dashboard")
            
            dashboard.section.header.val = {
              [[┌──────┬──────┬──────┬──────┐]],
              [[│  🌈  │  🚀  │  ✨  │  🎯  │]],
              [[├──────┼──────┼──────┼──────┤]],
              [[│   ADHD-FRIENDLY NEOVIM    │]],
              [[│    Focus \u2022 Flow \u2022 Fun     │]],
              [[└────────────────────────┘]],
            }
            
            dashboard.section.buttons.val = {
              dashboard.button("f", "🔍  Find file", ":Telescope find_files <CR>"),
              dashboard.button("e", "🌳  New file", ":ene <BAR> startinsert <CR>"),
              dashboard.button("r", "🕑  Recently used files", ":Telescope oldfiles <CR>"),
              dashboard.button("t", "🔍  Find text", ":Telescope live_grep <CR>"),
              dashboard.button("z", "🧞  Zen Mode", ":ZenMode<CR>"),
              dashboard.button("c", "⚙️   Configuration", ":e ~/.config/nvim/init.lua <CR>"),
              dashboard.button("q", "😴  Quit Neovim", ":qa<CR>"),
            }
            
            dashboard.section.footer.val = "Ready to be awesome! 🚀"
            alpha.setup(dashboard.opts)
          end)
          
          -- Notification System
          pcall(function()
            require("notify").setup({
              background_colour = "#000000",
              fps = 60,
              icons = {
                DEBUG = "🐛",
                ERROR = "❌",
                INFO = "ℹ️",
                TRACE = "✨",
                WARN = "⚠️"
              },
              level = 2,
              minimum_width = 50,
              render = "compact",
              stages = "fade_in_slide_out",
              timeout = 3000,
              top_down = true
            })
            vim.notify = require("notify")
          end)
          
          -- Noice UI Enhancements
          pcall(function()
            require("noice").setup({
              lsp = {
                override = {
                  ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                  ["vim.lsp.util.stylize_markdown"] = true,
                  ["cmp.entry.get_documentation"] = true,
                },
              },
              presets = {
                bottom_search = true,
                command_palette = true,
                long_message_to_split = true,
                inc_rename = false,
                lsp_doc_border = false,
              },
            })
          end)
          
          -- Smooth Scrolling
          pcall(function()
            require('neoscroll').setup({
              mappings = {'<C-u>', '<C-d>', '<C-b>', '<C-f>', '<C-y>', '<C-e>', 'zt', 'zz', 'zb'},
              hide_cursor = true,
              stop_eof = true,
              respect_scrolloff = false,
              cursor_scrolls_alone = true,
              easing_function = "quadratic",
            })
          end)
          
          -- Zen Mode Configuration
          pcall(function()
            require("zen-mode").setup({
              window = {
                backdrop = 0.95,
                width = 120,
                height = 1,
                options = {
                  signcolumn = "no",
                  number = false,
                  relativenumber = false,
                  cursorline = false,
                  cursorcolumn = false,
                  foldcolumn = "0",
                  list = false,
                },
              },
              plugins = {
                options = { enabled = true, ruler = false, showcmd = false },
                twilight = { enabled = true },
                gitsigns = { enabled = false },
                tmux = { enabled = false },
              },
            })
          end)
          
          -- Twilight Dimming
          pcall(function()
            require("twilight").setup({
              dimming = { alpha = 0.25, color = { "Normal", "#ffffff" }, term_bg = "#000000", inactive = false },
              context = 10,
              treesitter = true,
              expand = { "function", "method", "table", "if_statement" },
              exclude = {},
            })
          end)
          
          -- Color Highlighting
          pcall(function()
            require('colorizer').setup({
              filetypes = { "*" },
              user_default_options = {
                RGB = true, RRGGBB = true, names = true, RRGGBBAA = true, AARRGGBB = true,
                rgb_fn = true, hsl_fn = true, css = true, css_fn = true, mode = "background",
                tailwind = true, sass = { enable = true, parsers = { "css" } }, virtualtext = "●",
              },
            })
          end)
          
          -- TODO Comments
          pcall(function()
            require("todo-comments").setup({
              signs = true,
              sign_priority = 8,
              keywords = {
                FIX = { icon = " ", color = "error", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
                TODO = { icon = " ", color = "info" },
                HACK = { icon = " ", color = "warning" },
                WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
                PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
                NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
                TEST = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
              },
              gui_style = { fg = "NONE", bg = "BOLD" },
              merge_keywords = true,
              highlight = {
                multiline = true, multiline_pattern = "^.", multiline_context = 10,
                before = "", keyword = "wide", after = "fg",
                pattern = [[.*<(KEYWORDS)\\s*:]], comments_only = true,
                max_line_len = 400, exclude = {},
              },
              colors = {
                error = { "DiagnosticError", "ErrorMsg", "#DC2626" },
                warning = { "DiagnosticWarn", "WarningMsg", "#FBBF24" },
                info = { "DiagnosticInfo", "#2563EB" },
                hint = { "DiagnosticHint", "#10B981" },
                default = { "Identifier", "#7C3AED" },
                test = { "Identifier", "#FF006E" }
              },
              search = {
                command = "rg", args = { "--color=never", "--no-heading", "--with-filename", "--line-number", "--column" },
                pattern = [=[\\b(KEYWORDS):]],
              },
            })
          end)
          
          -- Enhanced Search with HLSLens
          pcall(function() require('hlslens').setup() end)
          
          -- Progress indicators for LSP
          pcall(function() 
            require("fidget").setup({
              progress = { display = { done_icon = "✓", progress_icon = { pattern = "dots", period = 1 } } },
              notification = { window = { winblend = 100 } },
            })
          end)
          
          -- Rainbow Delimiters
          pcall(function() require("rainbow-delimiters.setup").setup() end)
          
          -- Vim Illuminate
          pcall(function()
            require('illuminate').configure({
              providers = { 'lsp', 'treesitter', 'regex' },
              delay = 100, under_cursor = true, min_count_to_highlight = 1,
            })
          end)
          
          -- Note: satellite-nvim and smoothcursor-nvim are not available in nixpkgs
          -- Alternative: built-in scrollbar visualization and cursor highlighting via illuminate
        '';

        "nvim/lua/config/options.lua".text = ''
          local opt = vim.opt

          -- General
          opt.clipboard = "unnamedplus"
          opt.mouse = "a"
          opt.undofile = true
          opt.undolevels = 10000
          opt.backup = false
          opt.writebackup = false
          opt.swapfile = false

          -- EXTREME UI for maximum stimulation
          opt.number = true
          opt.relativenumber = true
          opt.signcolumn = "yes:3"  -- More space for signs
          opt.cursorline = true
          opt.cursorcolumn = true   -- ENABLE for maximum visual reference
          opt.termguicolors = true
          opt.background = "dark"
          opt.conceallevel = 0      -- Show everything!
          opt.showmode = true       -- Show mode for extra feedback
          opt.laststatus = 3
          opt.showtabline = 2
          opt.cmdheight = 1         -- Make command line visible
          opt.pumheight = 15        -- More completion items
          opt.pumblend = 0          -- No transparency for maximum contrast
          opt.winblend = 0

          -- Editing
          opt.expandtab = true
          opt.tabstop = 2
          opt.shiftwidth = 2
          opt.softtabstop = 2
          opt.autoindent = true
          opt.smartindent = true
          opt.wrap = false

          -- Search with MAXIMUM visibility
          opt.ignorecase = true
          opt.smartcase = true
          opt.hlsearch = true
          opt.incsearch = true
          opt.grepprg = "rg --vimgrep"

          -- Performance
          opt.updatetime = 100      -- Faster updates for instant feedback
          opt.timeoutlen = 300
          opt.lazyredraw = false    -- Always redraw for maximum responsiveness
          opt.synmaxcol = 500       -- More syntax highlighting

          -- Splits
          opt.splitright = true
          opt.splitbelow = true
          opt.scrolloff = 12        -- More context lines
          opt.sidescrolloff = 12

          -- MAXIMUM visual stimulation
          opt.list = true
          opt.listchars = "tab:▸ ,eol:↲,nbsp:⦸,trail:•,extends:⟩,precedes:⟨,space:·"
          opt.fillchars = "eob:~,fold:━,foldopen:▾,foldsep:│,foldclose:▸,diff:╱,msgsep:━,horiz:━,horizup:┻,horizdown:┳,vert:┃,vertleft:┫,vertright:┣,verthoriz:╋"
          opt.showbreak = "↪ "      -- Wrap indicator

          -- ADHD HYPERFOCUS settings
          opt.colorcolumn = "80,100,120" -- Multiple visual guides
          opt.smoothscroll = true
          opt.foldcolumn = "2"      -- Show fold markers
          
          -- Completion
          opt.completeopt = "menu,menuone,noselect,preview"
        '';

        "nvim/lua/config/keymaps.lua".text = ''
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

          -- Buffer management
          keymap("n", "<leader>bd", ":bdelete<CR>", { desc = "Delete buffer" })
          keymap("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev buffer" })
          keymap("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })

          -- Clear search highlighting
          keymap("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

          -- File explorer
          keymap("n", "<leader>e", ":Neotree toggle<CR>", { desc = "Toggle file explorer" })
          keymap("n", "<leader>ge", ":Neotree git_status<CR>", { desc = "Git explorer" })

          -- Telescope
          keymap("n", "<leader>ff", ":Telescope find_files<CR>", { desc = "Find files" })
          keymap("n", "<leader>fw", ":Telescope live_grep<CR>", { desc = "Find word" })
          keymap("n", "<leader>fb", ":Telescope buffers<CR>", { desc = "Find buffers" })
          keymap("n", "<leader>fh", ":Telescope help_tags<CR>", { desc = "Find help" })
          keymap("n", "<leader>fr", ":Telescope oldfiles<CR>", { desc = "Find recent files" })

          -- Git
          keymap("n", "<leader>gg", ":LazyGit<CR>", { desc = "Open LazyGit" })
          keymap("n", "<leader>gb", ":Gitsigns blame_line<CR>", { desc = "Git blame line" })
          keymap("n", "<leader>gd", ":Gitsigns diffthis<CR>", { desc = "Git diff" })
          keymap("n", "<leader>gp", ":Gitsigns preview_hunk<CR>", { desc = "Preview hunk" })

          -- Trouble
          keymap("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
          keymap("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer Diagnostics (Trouble)" })

          -- Terminal
          keymap("n", "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", { desc = "Terminal (float)" })
          keymap("n", "<leader>th", "<cmd>ToggleTerm direction=horizontal<cr>", { desc = "Terminal (horizontal)" })

          -- Formatting
          keymap("n", "<leader>mp", function() require("conform").format({ lsp_fallback = true }) end, { desc = "Format document" })
          
          -- ADHD-friendly shortcuts
          keymap("n", "<leader>z", ":ZenMode<CR>", { desc = "Toggle Zen Mode" })
          keymap("n", "<leader>tw", ":Twilight<CR>", { desc = "Toggle Twilight" })
          keymap("n", "<leader>td", ":TodoTelescope<CR>", { desc = "Find TODOs" })
          keymap("n", "<leader>tn", function() require("todo-comments").jump_next() end, { desc = "Next TODO" })
          keymap("n", "<leader>tp", function() require("todo-comments").jump_prev() end, { desc = "Prev TODO" })
          
          -- Visual search enhancements
          keymap("n", "n", "<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>", { desc = "Next search result" })
          keymap("n", "N", "<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>", { desc = "Prev search result" })
        '';

        "nvim/lua/config/theme.lua".text = ''
          -- HYPER-STIMULATING ADHD THEME
          local colors = {
            bg = "#0a0a0f",
            bg_highlight = "#1a1a2e",
            bg_visual = "#2a2a50",
            fg = "#ffffff",
            fg_dark = "#e0e0ff",
            fg_gutter = "#666699",
            
            -- NEON EXPLOSION - Maximum visual stimulation
            blue = "#00ffff",      -- Electric cyan for functions
            cyan = "#00ff88",      -- Neon teal for constants  
            green = "#88ff00",     -- Laser green for strings
            magenta = "#ff00ff",   -- Hot pink for keywords
            red = "#ff0066",       -- Electric red for errors
            orange = "#ff8800",    -- Blazing orange for warnings
            yellow = "#ffff00",    -- Pure yellow for search
            purple = "#8800ff",    -- Electric purple for types
            pink = "#ff66cc",      -- Bright pink for special
            maroon = "#ff3366",    -- Hot coral for hints
            
            -- EXTREME contrast colors
            border = "#ff00aa",
            comment = "#9999ff",
            
            -- ADHD HYPERFOCUS colors
            focus = "#00aaff",     -- Blazing blue
            urgent = "#ff4400",    -- Danger orange
            calm = "#44ff44",      -- Soothing green
            glow = "#ffaa00",      -- Golden glow
            flash = "#ff0088",     -- Flash pink
            electric = "#00ffaa",  -- Electric mint
          }

          vim.cmd("highlight clear")
          if vim.fn.exists("syntax_on") then vim.cmd("syntax reset") end
          vim.o.background = "dark"
          vim.g.colors_name = "adhd_hyperstim"

          local function hl(group, opts)
            local cmd = "highlight " .. group
            if opts.fg then cmd = cmd .. " guifg=" .. opts.fg end
            if opts.bg then cmd = cmd .. " guibg=" .. opts.bg end
            if opts.style then cmd = cmd .. " gui=" .. opts.style end
            if opts.sp then cmd = cmd .. " guisp=" .. opts.sp end
            vim.cmd(cmd)
          end

          -- HYPER-STIMULATING syntax highlighting
          hl("Normal", { fg = colors.fg, bg = colors.bg })
          hl("Comment", { fg = colors.comment, style = "italic,bold" })
          hl("Constant", { fg = colors.electric, style = "bold,undercurl", sp = colors.cyan })
          hl("String", { fg = colors.green, style = "italic,bold" })
          hl("Function", { fg = colors.blue, style = "bold,undercurl", sp = colors.focus })
          hl("Keyword", { fg = colors.magenta, style = "italic,bold,undercurl", sp = colors.flash })
          hl("Type", { fg = colors.purple, style = "italic,bold" })
          hl("Identifier", { fg = colors.pink, style = "bold" })
          hl("Special", { fg = colors.orange, style = "bold,undercurl", sp = colors.glow })
          hl("PreProc", { fg = colors.flash, style = "bold" })
          hl("Statement", { fg = colors.magenta, style = "bold" })
          hl("Operator", { fg = colors.glow, style = "bold" })
          hl("Number", { fg = colors.electric, style = "bold" })
          hl("Boolean", { fg = colors.urgent, style = "bold" })
          
          -- EXTREME UI elements
          hl("CursorLine", { bg = colors.bg_highlight, style = "bold" })
          hl("CursorLineNr", { fg = colors.glow, bg = colors.bg_highlight, style = "bold,undercurl", sp = colors.focus })
          hl("LineNr", { fg = colors.fg_gutter, style = "bold" })
          hl("Visual", { bg = colors.bg_visual, fg = colors.glow, style = "bold" })
          hl("Search", { fg = colors.bg, bg = colors.yellow, style = "bold,undercurl", sp = colors.urgent })
          hl("IncSearch", { fg = colors.bg, bg = colors.glow, style = "bold,undercurl", sp = colors.flash })
          hl("ColorColumn", { bg = colors.bg_highlight })
          hl("StatusLine", { fg = colors.glow, bg = colors.bg_highlight, style = "bold" })
          hl("WinSeparator", { fg = colors.border, style = "bold" })
          
          -- BLAZING diagnostics
          hl("DiagnosticError", { fg = colors.red, style = "bold,undercurl", sp = colors.red })
          hl("DiagnosticWarn", { fg = colors.orange, style = "bold,undercurl", sp = colors.orange })
          hl("DiagnosticInfo", { fg = colors.blue, style = "bold" })
          hl("DiagnosticHint", { fg = colors.electric, style = "bold" })
          
          -- EXPLOSIVE TODO highlighting
          hl("TodoBgTODO", { fg = colors.bg, bg = colors.blue, style = "bold,undercurl", sp = colors.glow })
          hl("TodoFgTODO", { fg = colors.blue, style = "bold,undercurl", sp = colors.focus })
          hl("TodoBgFIX", { fg = colors.bg, bg = colors.red, style = "bold,undercurl", sp = colors.urgent })
          hl("TodoFgFIX", { fg = colors.red, style = "bold,undercurl", sp = colors.red })
          hl("TodoBgNOTE", { fg = colors.bg, bg = colors.green, style = "bold,undercurl", sp = colors.calm })
          hl("TodoFgNOTE", { fg = colors.green, style = "bold,undercurl", sp = colors.electric })
          
          -- PULSING match highlighting
          hl("MatchParen", { fg = colors.glow, bg = colors.bg_visual, style = "bold,undercurl", sp = colors.flash })
          
          -- GLOWING fold markers
          hl("Folded", { fg = colors.focus, bg = colors.bg_highlight, style = "italic,bold" })
          hl("FoldColumn", { fg = colors.glow, style = "bold" })
        '';

        "nvim/lua/config/lsp.lua".text = ''
          local lspconfig_ok, lspconfig = pcall(require, 'lspconfig')
          local cmp_nvim_lsp_ok, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
          
          if not lspconfig_ok then 
            vim.notify("LSP Config not found! Check plugin installation.", vim.log.levels.ERROR)
            return 
          end
          
          local capabilities = cmp_nvim_lsp_ok and cmp_nvim_lsp.default_capabilities() or vim.lsp.protocol.make_client_capabilities()
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
              local keymap = vim.keymap.set
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

          -- Diagnostic configuration
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
        '';

        "nvim/lua/config/plugins.lua".text = ''
          -- Enhanced completion with maximum visual feedback
          local cmp_ok, cmp = pcall(require, 'cmp')
          local luasnip_ok, luasnip = pcall(require, 'luasnip')
          
          if cmp_ok then
            cmp.setup({
              snippet = {
                expand = function(args)
                  if luasnip_ok then luasnip.lsp_expand(args.body) end
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
                  elseif luasnip_ok and luasnip.expand_or_jumpable() then
                    luasnip.expand_or_jump()
                  else
                    fallback()
                  end
                end, {'i', 's'}),
                ['<S-Tab>'] = cmp.mapping(function(fallback)
                  if cmp.visible() then
                    cmp.select_prev_item()
                  elseif luasnip_ok and luasnip.jumpable(-1) then
                    luasnip.jump(-1)
                  else
                    fallback()
                  end
                end, {'i', 's'}),
              }),
              window = {
                completion = cmp.config.window.bordered({
                  border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
                  winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:Visual,Search:None",
                }),
                documentation = cmp.config.window.bordered({
                  border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
                }),
              },
              experimental = { ghost_text = true },
            })
          end

          -- HYPER-STIMULATING plugin configurations
          pcall(function() 
            require("bufferline").setup({
              options = {
                indicator = { style = 'underline' },
                show_buffer_close_icons = true,
                show_close_icon = true,
                separator_style = "slant",
              }
            })
          end)
          
          pcall(function() 
            require("ibl").setup({
              indent = { char = "▎", highlight = "IblIndent" },
              scope = { enabled = true, char = "▎", highlight = "IblScope" },
            })
          end)
          
          pcall(function() 
            require("mini.indentscope").setup({
              symbol = "▎",
              options = { try_as_border = true },
            })
          end)
          
          pcall(function() 
            require("neo-tree").setup({
              close_if_last_window = false,
              popup_border_style = "rounded",
              enable_git_status = true,
              enable_diagnostics = true,
            })
          end)
          
          pcall(function() 
            require("telescope").setup({
              defaults = {
                prompt_prefix = "🔍 ",
                selection_caret = "➤ ",
                entry_prefix = "  ",
                border = true,
                borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
              }
            })
          end)
          
          pcall(function() 
            require("nvim-treesitter.configs").setup({ 
              highlight = { enable = true, additional_vim_regex_highlighting = false },
              indent = { enable = true },
            }) 
          end)
          
          pcall(function() 
            require("lualine").setup({
              options = {
                icons_enabled = true,
                theme = 'auto',
                component_separators = { left = '▎', right = '▎'},
                section_separators = { left = '▌', right = '▐'},
              },
              sections = {
                lualine_a = {'mode'},
                lualine_b = {'branch', 'diff', 'diagnostics'},
                lualine_c = {'filename'},
                lualine_x = {'encoding', 'fileformat', 'filetype'},
                lualine_y = {'progress'},
                lualine_z = {'location'}
              }
            })
          end)
          
          pcall(function() require("which-key").setup({}) end)
          pcall(function() require("gitsigns").setup({}) end)
          pcall(function() require("nvim-autopairs").setup({}) end)
          pcall(function() require("Comment").setup({}) end)
          pcall(function() require("conform").setup({
            formatters_by_ft = {
              lua = { "stylua" },
              nix = { "alejandra" },
              python = { "black" },
              javascript = { "prettier" },
              typescript = { "prettier" },
              rust = { "rustfmt" },
            },
            format_on_save = { timeout_ms = 500, lsp_fallback = true },
          }) end)
          pcall(function() require("trouble").setup({}) end)
          pcall(function() require("toggleterm").setup({}) end)
          pcall(function() require("persistence").setup({}) end)
        '';

        "nvim/lua/config/autocmds.lua".text = ''
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
            command = ":%s/\\\\s\\\\+$//e",
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
        '';


      };
    };
  };
}