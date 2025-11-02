{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.dev.nvim.enable {
    hjem.users.${config.user.name}.files = {
      ".config/nvim/init.lua".text = lib.mkAfter ''
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
      '';
    };
  };
}
