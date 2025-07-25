{
  config,
  lib,
  ...
}: let
  cfg = config.home.dev.nvim;
  opencodeCfg = config.home.dev.opencode;
  username = config.user.name;
in {
  config = lib.mkIf (cfg.enable && opencodeCfg.enable) {
    users.users.${username}.maid.file = {
      xdg_config."nvim/lua/opencode-config.lua".text = ''

          opencode.setup({
            -- API configuration
            api_key = nil, -- Uses opencode CLI authentication
            base_url = "http://localhost:3000", -- Default opencode server

            -- Editor integration
            auto_reload = true, -- Reload buffers when opencode modifies files
            show_progress = true, -- Show progress notifications

            -- Context injection settings
            max_context_lines = 1000, -- Maximum lines to include in context
            include_diagnostics = true, -- Include LSP diagnostics in context
            include_git_diff = true, -- Include git diff in context

            -- UI settings
            float_opts = {
              border = "rounded",
              width = 0.8,
              height = 0.8,
            },
          })

          -- Key mappings for opencode integration
          local opts = { noremap = true, silent = true }

          -- Send current file to opencode
          vim.keymap.set("n", "<leader>of", function()
            opencode.send_file()
          end, vim.tbl_extend("force", opts, { desc = "OpenCode: Send file" }))

          -- Send visual selection to opencode
          vim.keymap.set("v", "<leader>os", function()
            opencode.send_selection()
          end, vim.tbl_extend("force", opts, { desc = "OpenCode: Send selection" }))

          -- Send diagnostics to opencode
          vim.keymap.set("n", "<leader>od", function()
            opencode.send_diagnostics()
          end, vim.tbl_extend("force", opts, { desc = "OpenCode: Send diagnostics" }))

          -- Open opencode chat
          vim.keymap.set("n", "<leader>oc", function()
            opencode.open_chat()
          end, vim.tbl_extend("force", opts, { desc = "OpenCode: Open chat" }))

          -- Quick prompt with context
          vim.keymap.set("n", "<leader>op", function()
            local prompt = vim.fn.input("OpenCode prompt: ")
            if prompt ~= "" then
              opencode.send_prompt(prompt, { include_context = true })
            end
          end, vim.tbl_extend("force", opts, { desc = "OpenCode: Quick prompt" }))

          -- Explain current function/selection
          vim.keymap.set({"n", "v"}, "<leader>oe", function()
            opencode.explain_code()
          end, vim.tbl_extend("force", opts, { desc = "OpenCode: Explain code" }))

          -- Fix diagnostics with opencode
          vim.keymap.set("n", "<leader>ox", function()
            opencode.fix_diagnostics()
          end, vim.tbl_extend("force", opts, { desc = "OpenCode: Fix diagnostics" }))

          print("OpenCode keymaps registered successfully!")

          -- Create Which-Key mappings if available
          if pcall(require, "which-key") then
            require("which-key").register({
              ["<leader>o"] = {
                name = "OpenCode",
                f = "Send file",
                s = "Send selection",
                d = "Send diagnostics",
                c = "Open chat",
                p = "Quick prompt",
                e = "Explain code",
                x = "Fix diagnostics",
              }
            })
          end
        end

        -- Try to setup opencode immediately and on plugin load
        local function try_setup()
          if pcall(require, "opencode") then
            setup_opencode()
            return true
          end
          return false
        end

        -- Try setup immediately
        if not try_setup() then
          -- If not available, try again after a delay
          vim.defer_fn(function()
            if not try_setup() then
              -- Final attempt with PackChanged autocmd
              vim.api.nvim_create_autocmd("PackChanged", {
                callback = function()
                  vim.schedule(try_setup)
                end,
              })
            end
          end, 100)
        end
      '';

      xdg_config."nvim/lua/vim-pack-opencode.lua".text = ''
        -- Add opencode.nvim plugin to vim.pack
        vim.pack.add({
          "https://github.com/NickvanDyke/opencode.nvim",
        })

        -- Setup opencode.nvim with proper configuration
        vim.schedule(function()
          local success, opencode = pcall(require, "opencode")
          if success then
            -- Setup the plugin with default config
            opencode.setup({
              model_id = "gpt-4.1",
              provider_id = "github-copilot",
              auto_reload = false,
            })

            -- Set up keymaps as shown in the documentation
            local opts = { noremap = true, silent = true }

            vim.keymap.set({"n", "v"}, "<leader>ca", function()
              require("opencode").ask()
            end, vim.tbl_extend("force", opts, { desc = "Ask opencode" }))

            vim.keymap.set({"n", "v"}, "<leader>cA", function()
              require("opencode").ask("@file ")
            end, vim.tbl_extend("force", opts, { desc = "Ask opencode about current file" }))

            vim.keymap.set("n", "<leader>ce", function()
              require("opencode").prompt("Explain @cursor and its context")
            end, vim.tbl_extend("force", opts, { desc = "Explain code near cursor" }))

            vim.keymap.set("n", "<leader>cr", function()
              require("opencode").prompt("Review @file for correctness and readability")
            end, vim.tbl_extend("force", opts, { desc = "Review file" }))

            vim.keymap.set("n", "<leader>cf", function()
              require("opencode").prompt("Fix these @diagnostics")
            end, vim.tbl_extend("force", opts, { desc = "Fix errors" }))

            vim.keymap.set("v", "<leader>co", function()
              require("opencode").prompt("Optimize @selection for performance and readability")
            end, vim.tbl_extend("force", opts, { desc = "Optimize selection" }))

            vim.keymap.set("v", "<leader>cd", function()
              require("opencode").prompt("Add documentation comments for @selection")
            end, vim.tbl_extend("force", opts, { desc = "Document selection" }))

            vim.keymap.set("v", "<leader>ct", function()
              require("opencode").prompt("Add tests for @selection")
            end, vim.tbl_extend("force", opts, { desc = "Test selection" }))

            print("OpenCode.nvim loaded and configured successfully!")

            -- Create Which-Key mappings if available
            if pcall(require, "which-key") then
              require("which-key").register({
                ["<leader>o"] = {
                  name = "OpenCode",
                  a = "Ask opencode",
                  A = "Ask about file",
                  e = "Explain cursor",
                  r = "Review file",
                  f = "Fix errors",
                  o = "Optimize selection",
                  d = "Document selection",
                  t = "Test selection",
                }
              })
            end
          else
            print("Failed to load opencode.nvim: " .. tostring(opencode))
          end
        end)
      '';
    };
  };
}
