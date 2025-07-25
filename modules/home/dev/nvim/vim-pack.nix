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
        "https://git.sr.ht/~whynothugo/lsp_lines.nvim",
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
        -- File Navigation
        "https://github.com/stevearc/oil.nvim",
        "https://github.com/nvim-tree/nvim-web-devicons",
        -- UI Components (required by leetcode.nvim)
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

        -- Setup lsp_lines.nvim
        require("lsp_lines").setup()
        -- Disable virtual_text since lsp_lines replaces it
        vim.diagnostic.config({
          virtual_text = false,
        })

        local on_attach = function(client, bufnr)
          local opts = { buffer = bufnr, silent = true }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
          vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
          vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
          -- Toggle lsp_lines
          vim.keymap.set("n", "<leader>l", require("lsp_lines").toggle, opts)
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
              Search = { bg = "#f9e2af" },
              IncSearch = { bg = "#fab387" },
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
            color = { "Normal", "#1e1e2e" },
          },
          context = 15,
          treesitter = true,
        })
        -- Hardtime (Vim motion learning)
        require("hardtime").setup({
          disabled_filetypes = { "oil", "lazy", "mason" },
          max_count = 3,
          restriction_mode = "hint",
          disable_mouse = false,
        })
        -- Oil.nvim (Directory editor)
        require("oil").setup({
          default_file_explorer = true,
          columns = {
            "icon",
            "permissions",
            "size",
            "mtime",
          },
          buf_options = {
            buflisted = false,
            bufhidden = "hide",
          },
          win_options = {
            wrap = false,
            signcolumn = "no",
            cursorcolumn = false,
            foldcolumn = "0",
            spell = false,
            list = false,
            conceallevel = 3,
            concealcursor = "nvic",
          },
          delete_to_trash = true,
          skip_confirm_for_simple_edits = false,
          prompt_save_on_select_new_entry = true,
          cleanup_delay_ms = 2000,
          lsp_file_operations = {
            enabled = true,
            autosave_changes = false,
          },
          constrain_cursor = "editable",
          experimental_watch_for_changes = false,
          keymaps = {
            ["g?"] = "actions.show_help",
            ["<CR>"] = "actions.select",
            ["<C-s>"] = "actions.select_vsplit",
            ["<C-h>"] = "actions.select_split",
            ["<C-t>"] = "actions.select_tab",
            ["<C-p>"] = "actions.preview",
            ["<C-c>"] = "actions.close",
            ["<C-l>"] = "actions.refresh",
            ["-"] = "actions.parent",
            ["_"] = "actions.open_cwd",
            ["`"] = "actions.cd",
            ["~"] = "actions.tcd",
            ["gs"] = "actions.change_sort",
            ["gx"] = "actions.open_external",
            ["g."] = "actions.toggle_hidden",
            ["g\\"] = "actions.toggle_trash",
          },
          use_default_keymaps = true,
          view_options = {
            show_hidden = false,
            is_hidden_file = function(name, bufnr)
              return vim.startswith(name, ".")
            end,
            is_always_hidden = function(name, bufnr)
              return false
            end,
            sort = {
              { "type", "asc" },
              { "name", "asc" },
            },
          },
          float = {
            padding = 2,
            max_width = 0,
            max_height = 0,
            border = "rounded",
            win_options = {
              winblend = 0,
            },
            override = function(conf)
              return conf
            end,
          },
          preview = {
            max_width = 0.9,
            min_width = { 40, 0.4 },
            width = nil,
            max_height = 0.9,
            min_height = { 5, 0.1 },
            height = nil,
            border = "rounded",
            win_options = {
              winblend = 0,
            },
            update_on_cursor_moved = true,
          },
          progress = {
            max_width = 0.9,
            min_width = { 40, 0.4 },
            width = nil,
            max_height = { 10, 0.9 },
            min_height = { 5, 0.1 },
            height = nil,
            border = "rounded",
            minimized_border = "none",
            win_options = {
              winblend = 0,
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
        -- Leetcode (with proper dependency handling)
        local function setup_leetcode()
          local ok, leetcode = pcall(require, "leetcode")
          if ok then
            leetcode.setup({
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
          else
            vim.notify("Leetcode.nvim disabled: dependency issues", vim.log.levels.WARN)
          end
        end

        -- Delay leetcode setup to ensure all dependencies are loaded
        vim.defer_fn(setup_leetcode, 100)
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
