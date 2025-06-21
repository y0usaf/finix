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

  # Simple Neovim with jetpack plugin manager
  simpleNeovim = pkgs.neovim;
in {
  config = lib.mkIf cfg.enable {
    users.users.${username}.maid = {
      packages = [
        pkgs.lazygit
        pkgs.ripgrep
        pkgs.fd
        pkgs.tree-sitter
        pkgs.fzf
        pkgs.bat
        pkgs.delta
        simpleNeovim
        # LSP servers for jetpack to use
        pkgs.lua-language-server
        pkgs.nil
        pkgs.pyright
        pkgs.rust-analyzer
        pkgs.typescript-language-server
        pkgs.vscode-langservers-extracted
        pkgs.bash-language-server
        pkgs.marksman
        pkgs.yaml-language-server
        pkgs.dockerfile-language-server-nodejs
        pkgs.stylua
        pkgs.alejandra
        pkgs.black
        pkgs.prettier
        pkgs.rustfmt
      ];

      # Jetpack-based Neovim configuration
      file.xdg_config = {
        "nvim/init.lua".text = ''
          vim.g.mapleader = " "
          vim.g.maplocalleader = "\\"

          -- Bootstrap lazy.nvim
          local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
          if not vim.loop.fs_stat(lazypath) then
            vim.fn.system({
              "git",
              "clone",
              "--filter=blob:none",
              "httpshttps://github.com/folke/lazy.nvim.git",
              "--branch=stable",
              lazypath,
            })
          end
          vim.opt.rtp:prepend(lazypath)

          -- Setup lazy with plugins
          require("lazy").setup({
            -- Theme (Tokyo Night - Modern & Beautiful)
            {
              "folke/tokyonight.nvim",
              lazy = false,
              priority = 1000,
              opts = {
                style = "night", -- night, storm, day, moon
                transparent = true,
                terminal_colors = true,
                styles = {
                  comments = { italic = true },
                  keywords = { italic = true },
                  functions = { bold = true },
                  variables = {},
                  sidebars = "transparent",
                  floats = "transparent",
                },
                sidebars = { "qf", "help", "vista_kind", "terminal", "packer" },
                day_brightness = 0.3,
                hide_inactive_statusline = false,
                dim_inactive = false,
                lualine_bold = true,
                on_colors = function(colors)
                  colors.border = "#1a1b26"
                  colors.bg_statusline = "#16161e"
                end,
                on_highlights = function(highlights, colors)
                  highlights.CursorLineNr = { fg = colors.orange, bold = true }
                  highlights.LineNr = { fg = colors.dark3 }
                  highlights.FloatBorder = { fg = colors.border_highlight }
                  highlights.TelescopeBorder = { fg = colors.border_highlight }
                  highlights.WhichKeyFloat = { bg = colors.bg_dark }
                  highlights.LspFloatWinBorder = { fg = colors.border_highlight }
                end,
              },
              config = function(_, opts)
                require("tokyonight").setup(opts)
                vim.cmd.colorscheme("tokyonight-night")
              end,
            },

            -- Smooth Scrolling & Animations
            {
              "karb94/neoscroll.nvim",
              event = "VeryLazy",
              opts = {
                mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>", "<C-y>", "<C-e>", "zt", "zz", "zb" },
                hide_cursor = true,
                stop_eof = true,
                respect_scrolloff = false,
                cursor_scrolls_alone = true,
                easing_function = "quadratic",
                pre_hook = nil,
                post_hook = nil,
              },
            },

            -- Enhanced Notifications & UI
            {
              "folke/noice.nvim",
              event = "VeryLazy",
              dependencies = { "MunifTanjim/nui.nvim", "rcarriga/nvim-notify" },
              opts = {
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
                  lsp_doc_border = true,
                },
                views = {
                  cmdline_popup = {
                    border = { style = "rounded" },
                    filter_options = {},
                    win_options = { winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder" },
                  },
                },
              },
            },

            {
              "rcarriga/nvim-notify",
              opts = {
                background_colour = "#000000",
                fps = 60,
                icons = {
                  DEBUG = "🐛",
                  ERROR = "✘",
                  INFO = "ℹ",
                  TRACE = "✎",
                  WARN = "⚠",
                },
                level = 2,
                minimum_width = 50,
                render = "wrapped-compact",
                stages = "fade_in_slide_out",
                timeout = 3000,
                top_down = true,
              },
            },

            -- UI Enhancements
            {
              "nvim-lualine/lualine.nvim",
              event = "VeryLazy",
              opts = {
                options = {
                  theme = "tokyonight",
                  globalstatus = true,
                  component_separators = { left = "│", right = "│" },
                  section_separators = { left = "", right = "" },
                },
                sections = {
                  lualine_a = { { "mode", fmt = function(str) return str:sub(1,1) end } },
                  lualine_b = { "branch", "diff" },
                  lualine_c = { { "filename", path = 1 } },
                  lualine_x = { "diagnostics", "encoding", "filetype" },
                  lualine_y = { "progress" },
                  lualine_z = { "location" },
                },
              },
            },

            {
              "akinsho/bufferline.nvim",
              event = "VeryLazy",
              opts = {
                options = {
                  mode = "buffers",
                  diagnostics = "nvim_lsp",
                  show_buffer_close_icons = false,
                  show_close_icon = false,
                  color_icons = true,
                  separator_style = "slant",
                },
              },
            },

            -- LSP
            {
              "neovim/nvim-lspconfig",
              event = { "BufReadPre", "BufNewFile" },
              dependencies = {
                "hrsh7th/cmp-nvim-lsp",
              },
              config = function()
                local lspconfig = require("lspconfig")
                local capabilities = require("cmp_nvim_lsp").default_capabilities()

                local on_attach = function(client, bufnr)
                  local opts = { buffer = bufnr, silent = true }
                  vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
                  vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
                  vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
                  vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
                  vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
                  vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
                  vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
                end

                -- Setup servers
                local servers = { "lua_ls", "nil_ls", "pyright", "rust_analyzer", "tsserver", "bashls", "marksman" }
                for _, server in ipairs(servers) do
                  lspconfig[server].setup({
                    capabilities = capabilities,
                    on_attach = on_attach,
                    settings = server == "lua_ls" and {
                      Lua = { diagnostics = { globals = { "vim" } } }
                    } or {},
                  })
                end
              end,
            },

            -- Completion
            {
              "hrsh7th/nvim-cmp",
              event = "InsertEnter",
              dependencies = {
                "hrsh7th/cmp-nvim-lsp",
                "hrsh7th/cmp-buffer",
                "hrsh7th/cmp-path",
                "L3MON4D3/LuaSnip",
                "saadparwaiz1/cmp_luasnip",
              },
              config = function()
                local cmp = require("cmp")
                local luasnip = require("luasnip")

                cmp.setup({
                  snippet = {
                    expand = function(args)
                      luasnip.lsp_expand(args.body)
                    end,
                  },
                  mapping = cmp.mapping.preset.insert({
                    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"] = cmp.mapping.scroll_docs(4),
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-e>"] = cmp.mapping.abort(),
                    ["<CR>"] = cmp.mapping.confirm({ select = true }),
                    ["<Tab>"] = cmp.mapping(function(fallback)
                      if cmp.visible() then
                        cmp.select_next_item()
                      elseif luasnip.expand_or_jumpable() then
                        luasnip.expand_or_jump()
                      else
                        fallback()
                      end
                    end, { "i", "s" }),
                  }),
                  sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "luasnip" },
                  }, {
                    { name = "buffer" },
                    { name = "path" },
                  }),
                })
              end,
            },

            -- File management
            {
              "nvim-telescope/telescope.nvim",
              cmd = "Telescope",
              dependencies = { "nvim-lua/plenary.nvim" },
              opts = {
                defaults = {
                  file_ignore_patterns = { "node_modules", ".git/" },
                  layout_config = {
                    horizontal = { preview_width = 0.6 },
                  },
                },
              },
            },

            {
              "nvim-neo-tree/neo-tree.nvim",
              cmd = "Neotree",
              dependencies = {
                "nvim-lua/plenary.nvim",
                "nvim-tree/nvim-web-devicons",
                "MunifTanjim/nui.nvim",
              },
              opts = {
                filesystem = {
                  follow_current_file = { enabled = true },
                  hijack_netrw_behavior = "open_current",
                },
                window = { width = 35 },
              },
            },

            -- Enhanced Git with animations
            {
              "lewis6991/gitsigns.nvim",
              event = { "BufReadPre", "BufNewFile" },
              opts = {
                signs = {
                  add = { text = "┃" },
                  change = { text = "┃" },
                  delete = { text = " " },
                  topdelete = { text = "▔" },
                  changedelete = { text = "~" },
                  untracked = { text = "┆" },
                },
                signs_staged = {
                  add = { text = "┃" },
                  change = { text = "┃" },
                  delete = { text = " " },
                  topdelete = { text = "▔" },
                  changedelete = { text = "~" },
                  untracked = { text = "┆" },
                },
                signs_staged_enable = true,
                signcolumn = true,
                numhl = false,
                linehl = false,
                word_diff = false,
                watch_gitdir = {
                  follow_files = true,
                },
                auto_attach = true,
                attach_to_untracked = false,
                current_line_blame = true,
                current_line_blame_opts = {
                  virt_text = true,
                  virt_text_pos = "eol",
                  delay = 300,
                  ignore_whitespace = false,
                  virt_text_priority = 100,
                },
                current_line_blame_formatter = "<author>, <author_time:%R> - <summary>",
                sign_priority = 6,
                update_debounce = 100,
                status_formatter = nil,
                max_file_length = 40000,
                preview_config = {
                  border = "rounded",
                  style = "minimal",
                  relative = "cursor",
                  row = 0,
                  col = 1,
                },
              },
              config = function(_, opts)
                require("gitsigns").setup(opts)

                -- Custom highlight groups for animated git signs
                vim.api.nvim_set_hl(0, "GitSignsAdd", { fg = "#98be65", bold = true })
                vim.api.nvim_set_hl(0, "GitSignsChange", { fg = "#ECBE7B", bold = true })
                vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = "#EC5F67", bold = true })
                vim.api.nvim_set_hl(0, "GitSignsCurrentLineBlame", { fg = "#565f89", italic = true })
              end,
            },

            -- Syntax highlighting with Nix+Lua injection
            {
              "nvim-treesitter/nvim-treesitter",
              build = ":TSUpdate",
              event = { "BufReadPost", "BufNewFile" },
              opts = {
                highlight = { enable = true, additional_vim_regex_highlighting = false },
                indent = { enable = true },
                ensure_installed = {
                  "lua", "nix", "python", "rust", "typescript", "javascript",
                  "bash", "markdown", "json", "yaml", "toml"
                },
              },
              config = function(_, opts)
                require("nvim-treesitter.configs").setup(opts)
              end,
            },

            -- Winbar with breadcrumbs
            {
              "utilyre/barbecue.nvim",
              name = "barbecue",
              version = "*",
              dependencies = {
                "SmiteshP/nvim-navic",
                "nvim-tree/nvim-web-devicons",
              },
              opts = {
                theme = "tokyonight",
                show_dirname = false,
                show_basename = false,
                create_autocmd = false,
                attach_navic = false,
                symbols = {
                  separator = "",
                },
                kinds = {
                  File = "",
                  Module = "",
                  Namespace = "",
                  Package = "",
                  Class = "",
                  Method = "",
                  Property = "",
                  Field = "",
                  Constructor = "",
                  Enum = "",
                  Interface = "",
                  Function = "",
                  Variable = "",
                  Constant = "",
                  String = "",
                  Number = "",
                  Boolean = "",
                  Array = "",
                  Object = "",
                  Key = "",
                  Null = "",
                  EnumMember = "",
                  Struct = "",
                  Event = "",
                  Operator = "",
                  TypeParameter = "",
                },
              },
              config = function(_, opts)
                require("barbecue").setup(opts)
                vim.api.nvim_create_autocmd({
                  "WinScrolled",
                  "BufWinEnter",
                  "CursorHold",
                  "InsertLeave",
                }, {
                  group = vim.api.nvim_create_augroup("barbecue.updater", {}),
                  callback = function()
                    require("barbecue.ui").update()
                  end,
                })
              end,
            },

            -- Holographic cursor and animations
            {
              "gen740/SmoothCursor.nvim",
              event = "VeryLazy",
              opts = {
                type = "default",
                cursor = "",
                texthl = "SmoothCursor",
                linehl = nil,
                fancy = {
                  enable = true,
                  head = { cursor = "▷", texthl = "SmoothCursor", linehl = nil },
                  body = {
                    { cursor = "󰝥", texthl = "SmoothCursorRed" },
                    { cursor = "󰝥", texthl = "SmoothCursorOrange" },
                    { cursor = "●", texthl = "SmoothCursorYellow" },
                    { cursor = "●", texthl = "SmoothCursorGreen" },
                    { cursor = "•", texthl = "SmoothCursorAqua" },
                    { cursor = ".", texthl = "SmoothCursorBlue" },
                    { cursor = ".", texthl = "SmoothCursorPurple" },
                  },
                  tail = { cursor = nil, texthl = "SmoothCursor" },
                },
                matrix = {
                  head = {
                    cursor = { "ア", "イ", "ウ", "エ", "オ", "カ", "キ", "ク", "ケ", "コ", "サ", "シ", "ス", "セ", "ソ", "タ", "チ", "ツ", "テ", "ト", "ナ", "ニ", "ヌ", "ネ", "ノ", "ハ", "ヒ", "フ", "ヘ", "ホ", "マ", "ミ", "ム", "メ", "モ", "ヤ", "ユ", "ヨ", "ラ", "リ", "ル", "レ", "ロ", "ワ", "ヲ", "ン" },
                    texthl = "SmoothCursor",
                    linehl = nil,
                  },
                  body = {
                    length = 6,
                    cursor = { "ア", "イ", "ウ", "エ", "オ", "カ", "キ", "ク", "ケ", "コ", "サ", "シ", "ス", "セ", "ソ", "タ", "チ", "ツ", "テ", "ト", "ナ", "ニ", "ヌ", "ネ", "ノ", "ハ", "ヒ", "フ", "ヘ", "ホ", "マ", "ミ", "ム", "メ", "モ", "ヤ", "ユ", "ヨ", "ラ", "リ", "ル", "レ", "ロ", "ワ", "ヲ", "ン" },
                    texthl = "SmoothCursorGreen",
                  },
                  tail = {
                    cursor = nil,
                    texthl = "SmoothCursor",
                  },
                  unstop = false,
                },
                autostart = true,
                always_redraw = true,
                flyin_effect = nil,
                speed = 25,
                intervals = 35,
                priority = 10,
                timeout = 3000,
                threshold = 3,
                disable_float_win = false,
                enabled_filetypes = nil,
                disabled_filetypes = nil,
              },
              config = function(_, opts)
                require("smoothcursor").setup(opts)

                -- Define highlight groups for cursor trail
                local colors = {
                  "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7", "#DDA0DD", "#98D8C8"
                }
                for i, color in ipairs(colors) do
                  vim.api.nvim_set_hl(0, "SmoothCursor" .. (i == 1 and "Red" or i == 2 and "Orange" or i == 3 and "Yellow" or i == 4 and "Green" or i == 5 and "Aqua" or i == 6 and "Blue" or "Purple"), { fg = color })
                end
                vim.api.nvim_set_hl(0, "SmoothCursor", { fg = "#8aa2d3" })
              end,
            },

            -- Rainbow brackets
            {
              "HiPhish/rainbow-delimiters.nvim",
              event = { "BufReadPost", "BufNewFile" },
              config = function()
                local rainbow_delimiters = require("rainbow-delimiters")
                vim.g.rainbow_delimiters = {
                  strategy = {
                    [""] = rainbow_delimiters.strategy["global"],
                    vim = rainbow_delimiters.strategy["local"],
                  },
                  query = {
                    [""] = "rainbow-delimiters",
                    lua = "rainbow-blocks",
                  },
                  priority = {
                    [""] = 110,
                    lua = 210,
                  },
                  highlight = {
                    'RainbowDelimiterRed',
                    'RainbowDelimiterYellow',
                    'RainbowDelimiterBlue',
                    'RainbowDelimiterOrange',
                    'RainbowDelimiterGreen',
                    'RainbowDelimiterViolet',
                    'RainbowDelimiterCyan',
                  },
                }
              end,
            },

            -- Minimap
            {
              "gorbit99/codewindow.nvim",
              event = { "BufReadPost", "BufNewFile" },
              opts = {
                auto_enable = false,
                minimap_width = 20,
                relative = "editor",
                border = "rounded",
                window_border = "rounded",
                show_cursor = true,
                screen_bounds = "lines",
                use_lsp = true,
                use_treesitter = true,
                use_git = true,
                width_multiplier = 4,
                z_index = 1,
                show_fold = true,
              },
              config = function(_, opts)
                local codewindow = require("codewindow")
                codewindow.setup(opts)
                vim.keymap.set("n", "<leader>mo", codewindow.toggle_minimap, { desc = "Toggle minimap" })
              end,
            },

            -- Utilities
            { "numToStr/Comment.nvim", event = "VeryLazy", opts = {} },
            { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },
            { "folke/which-key.nvim", event = "VeryLazy", opts = {} },
            {
              "lukas-reineke/indent-blankline.nvim",
              event = { "BufReadPost", "BufNewFile" },
              main = "ibl",
              opts = {
                indent = {
                  char = "▏",
                  tab_char = "▏",
                  highlight = { "RainbowRed", "RainbowYellow", "RainbowBlue", "RainbowOrange", "RainbowGreen", "RainbowViolet", "RainbowCyan" },
                },
                scope = {
                  enabled = true,
                  show_start = true,
                  show_end = true,
                  highlight = { "Function", "Label" },
                },
                exclude = {
                  filetypes = { "help", "alpha", "dashboard", "neo-tree", "Trouble", "lazy", "mason", "notify", "toggleterm", "lazyterm" },
                },
              },
            },

            -- Enhanced Terminal with blur
            {
              "akinsho/toggleterm.nvim",
              cmd = { "ToggleTerm", "TermExec" },
              opts = {
                size = 20,
                open_mapping = [[<c-\>]],
                direction = "float",
                shade_terminals = false,
                float_opts = {
                  border = "curved",
                  width = math.floor(vim.o.columns * 0.8),
                  height = math.floor(vim.o.lines * 0.8),
                  winblend = 20,
                  highlights = {
                    border = "Normal",
                    background = "Normal",
                  },
                },
                highlights = {
                  Normal = { guibg = "#1a1b26" },
                  NormalFloat = { link = "Normal" },
                  FloatBorder = { guifg = "#7aa2f7", guibg = "#1a1b26" },
                },
              },
              config = function(_, opts)
                require("toggleterm").setup(opts)

                -- Custom terminal with matrix effect
                local Terminal = require("toggleterm.terminal").Terminal
                local matrix_term = Terminal:new({
                  cmd = "cmatrix -C blue",
                  direction = "float",
                  float_opts = {
                    border = "curved",
                    width = math.floor(vim.o.columns * 0.6),
                    height = math.floor(vim.o.lines * 0.6),
                    winblend = 30,
                  },
                  on_open = function(term)
                    vim.cmd("startinsert!")
                    vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", {noremap = true, silent = true})
                  end,
                })

                vim.keymap.set("n", "<leader>tm", function() matrix_term:toggle() end, { desc = "Toggle matrix terminal" })
              end,
            },

            -- Diagnostics
            {
              "folke/trouble.nvim",
              cmd = { "Trouble", "TroubleToggle" },
              opts = { use_diagnostic_signs = true },
            },
          }, {
            ui = {
              border = "rounded",
              icons = {
                cmd = "⌘",
                config = "🛠",
                event = "📅",
                ft = "📂",
                init = "⚙",
                keys = "🗝",
                plugin = "🔌",
                runtime = "💻",
                source = "📄",
                start = "🚀",
                task = "📌",
              },
            },
          })

          -- Enhanced vim options with Tokyo Night visual improvements
          vim.opt.number = true
          vim.opt.relativenumber = true
          vim.opt.signcolumn = "yes"
          vim.opt.wrap = false
          vim.opt.expandtab = true
          vim.opt.tabstop = 2
          vim.opt.shiftwidth = 2
          vim.opt.clipboard = "unnamedplus"
          vim.opt.ignorecase = true
          vim.opt.smartcase = true
          vim.opt.termguicolors = true
          vim.opt.updatetime = 250
          vim.opt.timeoutlen = 300
          vim.opt.scrolloff = 8
          vim.opt.sidescrolloff = 8
          vim.opt.cursorline = true
          vim.opt.cursorlineopt = "both"
          vim.opt.mouse = "a"
          vim.opt.pumheight = 15
          vim.opt.pumblend = 15
          vim.opt.winblend = 15
          vim.opt.conceallevel = 2
          vim.opt.concealcursor = "niv"
          vim.opt.showmode = false
          vim.opt.laststatus = 3
          vim.opt.cmdheight = 0
          vim.opt.fillchars = { eob = " ", fold = " ", foldsep = " ", diff = "/" }
          vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
          vim.opt.shortmess:append({ W = true, I = true, c = true, C = true })
          vim.opt.splitbelow = true
          vim.opt.splitright = true
          vim.opt.splitkeep = "screen"
          vim.opt.smoothscroll = true

          -- Keymaps
          local keymap = vim.keymap.set

          -- File operations
          keymap("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
          keymap("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Live grep" })
          keymap("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Find buffers" })
          keymap("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Recent files" })
          keymap("n", "<leader>e", "<cmd>Neotree toggle<cr>", { desc = "File explorer" })

          -- Buffer navigation
          keymap("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
          keymap("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
          keymap("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })

          -- Window navigation
          keymap("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
          keymap("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
          keymap("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
          keymap("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

          -- Diagnostics
          keymap("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Toggle diagnostics" })
          keymap("n", "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer diagnostics" })

          -- Quick actions
          keymap("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })
          keymap("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })
          keymap("n", "<leader>/", function() require("Comment.api").toggle.linewise.current() end, { desc = "Toggle comment" })
          keymap("v", "<leader>/", "<esc><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<cr>", { desc = "Toggle comment" })

          -- Better up/down
          keymap({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
          keymap({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

          -- Move Lines
          keymap("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move down" })
          keymap("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move up" })
          keymap("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move down" })
          keymap("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move up" })
          keymap("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move down" })
          keymap("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move up" })

          -- Better indenting
          keymap("v", "<", "<gv")
          keymap("v", ">", ">gv")

          -- Auto-install missing parsers when entering buffer
          vim.api.nvim_create_autocmd("FileType", {
            callback = function()
              local parsers = require("nvim-treesitter.parsers")
              local lang = parsers.get_buf_lang()
              if parsers.get_parser_configs()[lang] and not parsers.has_parser(lang) then
                vim.schedule(function()
                  vim.cmd("TSInstall " .. lang)
                end)
              end
            end,
          })

          print("🚀 Modern Neovim IDE loaded!")
        '';
      };
    };
  };
}
