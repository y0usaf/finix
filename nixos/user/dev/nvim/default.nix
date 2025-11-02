{
  config,
  lib,
  ...
}: let
  nvim = import ../../../../lib/nvim;
in {
  imports = [
    ./neovide.nix
    ./options.nix
    ./packages.nix
  ];

  config = lib.mkIf config.user.dev.nvim.enable {
    hjem.users.${config.user.name}.files = {
      ".config/nvim/init.lua".text = ''
        -- Leader keys
        vim.g.mapleader = " "
        vim.g.maplocalleader = "\\"

        -- Load plugins
        vim.pack.add({
          ${lib.concatMapStringsSep ",\n          " (p: "\"${p}\"") nvim.plugins}
        })

        ${nvim.settings}

        -- Disable netrw for neo-tree
        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1

        -- UFO folding settings
        vim.opt.foldcolumn = "1"
        vim.opt.foldlevel = 99
        vim.opt.foldlevelstart = 99
        vim.opt.foldenable = true

        -- Neo-tree setup
        require("neo-tree").setup({
          close_if_last_window = true,
          popup_border_style = "rounded",
          enable_git_status = true,
          enable_diagnostics = true,
          default_component_configs = {
            indent = {
              indent_size = 2,
              padding = 1,
            },
            icon = {
              folder_closed = "",
              folder_open = "",
              folder_empty = "ﰊ",
              default = "*",
            },
            git_status = {
              symbols = {
                added = "✚",
                deleted = "✖",
                modified = "",
                renamed = "",
                untracked = "",
                ignored = "",
                unstaged = "",
                staged = "",
                conflict = "",
              }
            },
          },
          window = {
            position = "left",
            width = 40,
            mappings = {
              ["<space>"] = "toggle_node",
              ["<2-LeftMouse>"] = "open",
              ["<cr>"] = "open",
              ["o"] = "open",
              ["S"] = "open_split",
              ["s"] = "open_vsplit",
              ["t"] = "open_tabnew",
              ["C"] = "close_node",
              ["a"] = "add",
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
            }
          },
          filesystem = {
            filtered_items = {
              visible = false,
              hide_dotfiles = false,
              hide_gitignored = false,
            },
            follow_current_file = {
              enabled = true,
            },
            use_libuv_file_watcher = true,
          },
          git_status = {
            window = {
              position = "float",
              mappings = {
                ["A"] = "git_add_all",
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

        -- Plugin configurations
        -- Telescope setup
        require("telescope").setup({})
        pcall(require("telescope").load_extension, "fzf")

        -- LSP setup
        local lspconfig = require("lspconfig")
        local capabilities = require("cmp_nvim_lsp").default_capabilities()
        require("lsp_lines").setup()
        vim.diagnostic.config({ virtual_text = false })

        local on_attach = function(client, bufnr)
          local opts = { buffer = bufnr, silent = true }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
          vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
          vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
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

        -- Completion setup
        local cmp = require("cmp")
        local luasnip = require("luasnip")
        local lspkind = require("lspkind")
        cmp.setup({
          snippet = {
            expand = function(args) luasnip.lsp_expand(args.body) end,
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

        -- Other plugin setups
        require("nvim-treesitter.configs").setup({
          highlight = { enable = true },
          indent = { enable = true },
        })

        require("cyberdream").setup({
          transparent = true,
          italic_comments = true,
          borderless_pickers = true,
          lualine_style = "default",
          theme = {
            variant = "default",
            highlights = {
              -- Core UI colors matching neon dark theme
              Normal = { bg = "#0f0f0f", fg = "#ffffff" },
              NormalNC = { bg = "#0f0f0f", fg = "#b4b4b4" },

              -- Active/focused elements (neon green)
              CursorLine = { bg = "#1a1a1a" },
              Visual = { bg = "#003d2a" },
              Search = { bg = "#00ff96", fg = "#000000" },
              IncSearch = { bg = "#00ff64", fg = "#000000" },

              -- Errors and warnings (neon pink/orange)
              Error = { fg = "#ff0064" },
              ErrorMsg = { fg = "#ff0064" },
              WarningMsg = { fg = "#ff6400" },
              DiagnosticError = { fg = "#ff0064" },
              DiagnosticWarn = { fg = "#ff6400" },

              -- Success states (neon green)
              DiagnosticOk = { fg = "#00ff64" },
              DiagnosticHint = { fg = "#00ff96" },

              -- Highlights and info (neon cyan)
              DiagnosticInfo = { fg = "#00c8ff" },
              Comment = { fg = "#808080", italic = true },

              -- Syntax highlighting with neon accents
              String = { fg = "#00ff64" },
              Function = { fg = "#00c8ff" },
              Keyword = { fg = "#c800ff" },
              Type = { fg = "#00ff96" },
              Constant = { fg = "#ff6400" },
              Special = { fg = "#ff007f" },

              -- UI borders and separators
              FloatBorder = { fg = "#00ff96" },
              WinSeparator = { fg = "#404040" },

              -- Tab line
              TabLine = { bg = "#1a1a1a", fg = "#808080" },
              TabLineSel = { bg = "#00ff96", fg = "#000000" },

              -- Status line
              StatusLine = { bg = "#1a1a1a", fg = "#ffffff" },
              StatusLineNC = { bg = "#0f0f0f", fg = "#808080" },

              -- Popup menus
              Pmenu = { bg = "#1a1a1a", fg = "#ffffff" },
              PmenuSel = { bg = "#00ff96", fg = "#000000" },
              PmenuBorder = { fg = "#00ff96" },
            },
          },
        })
        vim.cmd.colorscheme("cyberdream")

        require("lualine").setup({ options = { theme = "cyberdream", globalstatus = true } })
        require("gitsigns").setup({ current_line_blame = true })
        require("ibl").setup({})
        require("Comment").setup({})
        require("nvim-autopairs").setup({})
        require("ufo").setup({})
        require("fidget").setup({})
        require("illuminate").configure({})
        require("twilight").setup({})
        require("toggleterm").setup({ direction = "float" })
        require("flash").setup({})
        require("mini.hipatterns").setup({})
        require("dropbar").setup({})
        require("dressing").setup({})
        require("windows").setup({})

        ${nvim.keymaps}
      '';
    };
  };
}
