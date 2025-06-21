# All Neovim plugins configuration module
{
  config,
  lib,
  ...
}: let
  cfg = config.home.dev.nvim;
  inherit (config.shared) username;
in {
  config = lib.mkIf cfg.enable {
    users.users.${username}.maid.file.xdg_config."nvim/init.lua".text = ''
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

        -- Git integration
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
            current_line_blame = true,
          },
        },

        -- Syntax highlighting
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

        -- Utilities
        { "numToStr/Comment.nvim", event = "VeryLazy", opts = {} },
        { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },
        { "folke/which-key.nvim", event = "VeryLazy", opts = {} },

        -- Diagnostics
        {
          "folke/trouble.nvim",
          cmd = { "Trouble", "TroubleToggle" },
          opts = { use_diagnostic_signs = true },
        },
      }, {
        ui = {
          border = "rounded",
        },
      })

      print("🚀 Modern Neovim IDE loaded!")
    '';
  };
}