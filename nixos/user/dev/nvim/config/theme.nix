{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.user.dev.nvim.enable {
    hjem.users.${config.user.name}.files = {
      ".config/nvim/init.lua".text = lib.mkAfter ''
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
      '';
    };
  };
}
