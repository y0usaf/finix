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

            -- Setup servers (minimal essential set)
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
          event = "VeryLazy",
          dependencies = {
            "nvim-lua/plenary.nvim",
            {
              "nvim-telescope/telescope-fzf-native.nvim",
              build = "make",
            },
          },
          config = function()
            local telescope = require("telescope")
            telescope.setup({
              defaults = {
                path_display = { "truncate" },
                mappings = {
                  i = {
                    ["<C-k>"] = "move_selection_previous",
                    ["<C-j>"] = "move_selection_next",
                  },
                },
                preview = {
                  treesitter = false,
                },
              },
            })
            telescope.load_extension("fzf")
          end,
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

        -- Visual enhancements for ADHD focus
        {
          "NvChad/nvim-colorizer.lua",
          event = "VeryLazy",
          config = function()
            require("colorizer").setup()
          end,
        },
        {
          "utilyre/barbecue.nvim",
          event = "VeryLazy",
          dependencies = {
            "SmiteshP/nvim-navic",
            "nvim-tree/nvim-web-devicons",
          },
          opts = {
            theme = "cyberdream",
            show_dirname = false,
            show_basename = false,
          },
        },
        {
          "echasnovski/mini.animate",
          event = "VeryLazy",
          config = function()
            require("mini.animate").setup({
              cursor = {
                enable = true,
                timing = function() return 25 end,
              },
              scroll = {
                enable = true,
                timing = function() return 50 end,
              },
              resize = {
                enable = true,
                timing = function() return 25 end,
              },
              open = {
                enable = true,
                timing = function() return 50 end,
              },
              close = {
                enable = true,
                timing = function() return 50 end,
              },
            })
          end,
        },
        {
          "kevinhwang91/nvim-ufo",
          event = "VeryLazy",
          dependencies = "kevinhwang91/promise-async",
          opts = {
            provider_selector = function()
              return { "treesitter", "indent" }
            end,
          },
          init = function()
            vim.o.foldcolumn = "1"
            vim.o.foldlevel = 99
            vim.o.foldlevelstart = 99
            vim.o.foldenable = true
          end,
        },
        {
          "j-hui/fidget.nvim",
          event = "LspAttach",
          opts = {
            notification = {
              window = {
                winblend = 0,
                border = "rounded",
              },
            },
            progress = {
              display = {
                render_limit = 3,
                done_ttl = 2,
              },
            },
          },
        },
        {
          "folke/twilight.nvim",
          cmd = "Twilight",
          opts = {
            dimming = {
              alpha = 0.25,
              color = { "Normal", "#ffffff" },
            },
            context = 15,
            treesitter = true,
          },
        },

        -- Leetcode (kept for motivation)
        {
          "kawre/leetcode.nvim",
          cmd = "Leet",
          dependencies = {
            "nvim-telescope/telescope.nvim",
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
          },
          opts = {
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
          },
        },


      }
    '';
  };
}
