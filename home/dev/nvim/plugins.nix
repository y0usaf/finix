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
    users.users.${username}.maid.file.xdg_config."nvim/lua/plugins.lua".text = ''
      -- Setup lazy with plugins
      return {
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
            local servers = { "lua_ls", "nil_ls", "pyright", "rust_analyzer", "ts_ls", "bashls", "marksman" }
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
            "onsails/lspkind.nvim",
          },
          config = function()
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
                { name = "nvim_lsp" },
                { name = "luasnip" },
              }, {
                { name = "buffer" },
                { name = "path" },
              }),
              formatting = {
                format = lspkind.cmp_format({
                  mode = "symbol_text",
                  maxwidth = 50,
                  ellipsis_char = "...",
                }),
              },
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
      }
    '';
  };
}
