{
  config,
  lib,
  ...
}: let
  cfg = config.home.dev.nvim;
  username = "y0usaf";
in {
  config = lib.mkIf cfg.enable {
    users.users.${username}.maid.file.xdg_config."nvim/lua/vim-pack-config.lua".text = ''
      -- Core plugins with vim.pack
      vim.pack.add({
        -- LSP and Completion
        "https://github.com/neovim/nvim-lspconfig",
        "https://github.com/hrsh7th/nvim-cmp",
        "https://github.com/hrsh7th/cmp-nvim-lsp",
        "https://github.com/hrsh7th/cmp-buffer",
        "https://github.com/hrsh7th/cmp-path",
        "https://github.com/L3MON4D3/LuaSnip",
        "https://github.com/saadparwaiz1/cmp_luasnip",
        "https://github.com/onsails/lspkind.nvim",

        -- File Navigation & Search
        "https://github.com/nvim-telescope/telescope.nvim",
        "https://github.com/nvim-lua/plenary.nvim",
        { src = "https://github.com/nvim-telescope/telescope-fzf-native.nvim" },

        -- Syntax & Highlighting
        "https://github.com/nvim-treesitter/nvim-treesitter",

        -- Utilities
        "https://github.com/numToStr/Comment.nvim",
        "https://github.com/windwp/nvim-autopairs",
        "https://github.com/kevinhwang91/nvim-ufo",
        "https://github.com/kevinhwang91/promise-async",
        "https://github.com/j-hui/fidget.nvim",
        "https://github.com/RRethy/vim-illuminate",
        "https://github.com/folke/twilight.nvim",
        "https://github.com/m4xshen/hardtime.nvim",

        -- File Explorer
        "https://github.com/nvim-neo-tree/neo-tree.nvim",
        "https://github.com/nvim-tree/nvim-web-devicons",
        "https://github.com/MunifTanjim/nui.nvim",

        -- Terminal
        "https://github.com/akinsho/toggleterm.nvim",

        -- Theme & UI
        "https://github.com/scottmckendry/cyberdream.nvim",
        "https://github.com/Bekaboo/dropbar.nvim",
        "https://github.com/stevearc/dressing.nvim",
        "https://github.com/anuvyklack/windows.nvim",
        "https://github.com/anuvyklack/middleclass",
        "https://github.com/nvim-lualine/lualine.nvim",
        "https://github.com/lewis6991/gitsigns.nvim",
        "https://github.com/lukas-reineke/indent-blankline.nvim",
        "https://github.com/folke/flash.nvim",
        "https://github.com/echasnovski/mini.hipatterns",

        -- Specialized
        "https://github.com/kawre/leetcode.nvim",
      })

      -- LSP Configuration
      local function setup_lsp()
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

        local servers = { "lua_ls", "nil_ls", "pyright" }
        for _, server in ipairs(servers) do
          lspconfig[server].setup({
            capabilities = capabilities,
            on_attach = on_attach,
            settings = server == "lua_ls" and {
              Lua = { diagnostics = { globals = { "vim" } } }
            } or {},
          })
        end
      end

      -- Completion Configuration
      local function setup_completion()
        local cmp = require("cmp")
        local luasnip = require("luasnip")
        local lspkind = require("lspkind")

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
            { name = "nvim_lsp", priority = 1000 },
            { name = "luasnip", priority = 750 },
          }, {
            { name = "buffer", priority = 500, max_item_count = 5 },
            { name = "path", priority = 250, max_item_count = 3 },
          }),
          formatting = {
            format = lspkind.cmp_format({
              mode = "symbol_text",
              maxwidth = 50,
              ellipsis_char = "...",
            }),
          },
        })
      end

      -- Telescope Configuration
      local function setup_telescope()
        require("telescope").setup({})
        pcall(require("telescope").load_extension, "fzf")
      end

      -- Treesitter Configuration
      local function setup_treesitter()
        require("nvim-treesitter.configs").setup({
          highlight = { enable = true },
          indent = { enable = true },
        })
      end

      -- Theme Configuration
      local function setup_theme()
        require("cyberdream").setup({
          transparent = true,
          italic_comments = true,
          borderless_pickers = true,
          lualine_style = "default",
          theme = {
            variant = "default",
            highlights = {
              CursorLine = { bg = "#1e1e2e" },
              Visual = { bg = "#313244" },
              Search = { bg = "#f9e2af", fg = "#11111b" },
              IncSearch = { bg = "#fab387", fg = "#11111b" },
            },
          },
        })
        vim.cmd.colorscheme("cyberdream")
      end

      -- UI Configuration
      local function setup_ui()
        -- Lualine
        require("lualine").setup({
          options = { theme = "cyberdream", globalstatus = true },
        })

        -- Gitsigns
        require("gitsigns").setup({
          signs = {
            add = { text = "┃" },
            change = { text = "┃" },
            delete = { text = " " },
            topdelete = { text = "▔" },
            changedelete = { text = "~" },
            untracked = { text = "┆" },
          },
          current_line_blame = true,
        })

        -- Indent Blankline
        require("ibl").setup({
          indent = { char = "▏", tab_char = "▏" },
          scope = { enabled = true, char = "─", show_start = true, show_end = true },
        })

        -- Dropbar
        require("dropbar").setup({ menu = { preview = false } })

        -- Dressing
        require("dressing").setup({})

        -- Windows
        require("windows").setup({
          autowidth = { enable = true, winwidth = 5, filetype = { help = 2 } },
          ignore = {
            buftype = { "quickfix" },
            filetype = { "NvimTree", "neo-tree", "undotree", "gundo" },
          },
        })

        -- Flash
        require("flash").setup({})

        -- Mini Hipatterns
        local hipatterns = require("mini.hipatterns")
        hipatterns.setup({
          highlighters = {
            fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
            hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
            todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
            note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
            hex_color = hipatterns.gen_highlighter.hex_color(),
          },
        })
      end

      -- Other Plugin Configurations
      local function setup_other_plugins()
        -- Comment
        require("Comment").setup({})

        -- Autopairs
        require("nvim-autopairs").setup({})

        -- UFO (Folding)
        require("ufo").setup({})

        -- Fidget (Notifications)
        require("fidget").setup({
          notification = {
            window = { border = "rounded" },
          },
        })
        vim.notify = require("fidget").notify

        -- Illuminate
        require("illuminate").configure({
          delay = 100,
          large_file_cutoff = 2000,
          large_file_overrides = {
            providers = { "lsp" },
          },
        })

        -- Twilight
        require("twilight").setup({
          dimming = {
            alpha = 0.25,
            color = { "Normal", "#ffffff" },
          },
          context = 15,
          treesitter = true,
        })

        -- Hardtime (Vim motion learning)
        require("hardtime").setup({
          disabled_filetypes = { "neo-tree", "lazy", "mason", "oil" },
          max_count = 3,
          restriction_mode = "hint",
          disable_mouse = false,
        })

        -- Neo-tree
        require("neo-tree").setup({
          close_if_last_window = false,
          popup_border_style = "rounded",
          enable_git_status = true,
          enable_diagnostics = true,
          filesystem = {
            filtered_items = {
              visible = false,
              hide_dotfiles = false,
              hide_gitignored = false,
            },
            follow_current_file = {
              enabled = true,
              leave_dirs_open = false,
            },
            group_empty_dirs = false,
            hijack_netrw_behavior = "open_default",
            use_libuv_file_watcher = true,
          },
          window = {
            position = "left",
            width = 30,
            mapping_options = {
              noremap = true,
              nowait = true,
            },
            mappings = {
              ["<space>"] = "none",
              ["[g"] = "prev_git_modified",
              ["]g"] = "next_git_modified",
            },
          },
          default_component_configs = {
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
                renamed   = "󰁕",
                untracked = "",
                ignored   = "",
                unstaged  = "󰄱",
                staged    = "",
                conflict  = "",
              }
            },
          },
        })

        -- ToggleTerm
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

        -- Leetcode
        require("leetcode").setup({
          lang = "python3",
          storage = {
            home = "~/leetcode/",
          },
          logging = true,
          injector = {
            ["python3"] = {
              before = true,
            },
          },
        })
      end

      -- Setup plugins after pack operations or immediately if already available
      local function initialize_config()
        setup_lsp()
        setup_completion()
        setup_telescope()
        setup_treesitter()
        setup_theme()
        setup_ui()
        setup_other_plugins()
      end

      -- PackChanged autocmd triggers when vim.pack installs/updates plugins
      vim.api.nvim_create_autocmd("PackChanged", {
        callback = function()
          vim.schedule(initialize_config)
        end,
      })

      -- Setup immediately if plugins are already available
      vim.schedule(function()
        if pcall(require, "lspconfig") then
          initialize_config()
        end
      end)
    '';
  };
}
