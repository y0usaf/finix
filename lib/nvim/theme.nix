# Minimalist biophilic theme for Neovim
# Transparent background with sage/forest greens (nature) + dopamine warm accents
''
  require("cyberdream").setup({
    transparent = true,
    italic_comments = true,
    borderless_pickers = true,
    lualine_style = "default",
    theme = {
      variant = "default",
      highlights = {
        -- Core UI - soft, minimal
        Normal = { bg = "NONE", fg = "#e8e6e1" },
        NormalNC = { bg = "NONE", fg = "#d1ccc8" },

        -- Cursor and selection - subtle
        CursorLine = { bg = "#1a1f1a" },
        CursorColumn = { bg = "#1a1f1a" },
        Visual = { bg = "#2a3d2a" },

        -- Search - warm dopamine (gold)
        Search = { bg = "#3d3a2a", fg = "#d4a574" },
        IncSearch = { bg = "#4a4630", fg = "#e8c49d" },

        -- Diagnostics - nature-inspired with warmth
        DiagnosticError = { fg = "#e8997d" },
        DiagnosticWarn = { fg = "#d4a574" },
        DiagnosticInfo = { fg = "#7b9fb5" },
        DiagnosticHint = { fg = "#a8b5a8" },
        DiagnosticOk = { fg = "#a8c9a0" },

        -- Messages
        Error = { fg = "#e8997d" },
        ErrorMsg = { fg = "#e8997d" },
        WarningMsg = { fg = "#d4a574" },

        -- Syntax highlighting - nature palette
        String = { fg = "#a8c9a0" },        -- sage green
        Function = { fg = "#7b9fb5" },      -- soft blue (dopamine cool)
        Keyword = { fg = "#5a7d6b" },       -- forest green
        Type = { fg = "#a8b5a8" },          -- sage (muted)
        Constant = { fg = "#d4a574" },      -- gold (dopamine warm)
        Special = { fg = "#e8997d" },       -- coral (dopamine warm)
        Comment = { fg = "#7a8178", italic = true },

        -- UI Elements
        FloatBorder = { fg = "#a8b5a8" },
        WinSeparator = { fg = "#3a3f3a" },
        VertSplit = { fg = "#3a3f3a" },

        -- Lines and indicators
        LineNr = { fg = "#5a5f5a" },
        CursorLineNr = { fg = "#a8b5a8" },
        SignColumn = { bg = "NONE" },
        FoldColumn = { fg = "#5a7d6b", bg = "NONE" },

        -- Tabs and status
        TabLine = { bg = "NONE", fg = "#7a7f7a" },
        TabLineSel = { bg = "#2a3d2a", fg = "#a8b5a8" },
        TabLineFill = { bg = "NONE" },

        -- Status line (keep subtle)
        StatusLine = { bg = "#1a1f1a", fg = "#e8e6e1" },
        StatusLineNC = { bg = "NONE", fg = "#7a7f7a" },

        -- Popup menus - subtle with warmth highlights
        Pmenu = { bg = "#1a1f1a", fg = "#e8e6e1" },
        PmenuSel = { bg = "#2a3d2a", fg = "#e8c49d" },
        PmenuBorder = { fg = "#5a7d6b" },
        PmenuThumb = { bg = "#5a7d6b" },

        -- Diff and git
        DiffAdd = { fg = "#a8c9a0" },
        DiffDelete = { fg = "#e8997d" },
        DiffChange = { fg = "#d4a574" },
        DiffText = { fg = "#e8c49d", bold = true },

        -- Folding
        Folded = { bg = "#2a3d2a", fg = "#a8b5a8" },

        -- Spelling
        SpellBad = { sp = "#e8997d", undercurl = true },
        SpellCap = { sp = "#d4a574", undercurl = true },
        SpellLocal = { sp = "#7b9fb5", undercurl = true },
        SpellRare = { sp = "#a8b5a8", undercurl = true },

        -- Matchparen
        MatchParen = { fg = "#e8c49d", bold = true },

        -- Visual mode
        VisualNOS = { bg = "#2a3d2a" },
      },
    },
  })
  vim.cmd.colorscheme("cyberdream")

  require("lualine").setup({
    options = {
      theme = "cyberdream",
      globalstatus = true,
      section_separators = { left = "", right = "" },
      component_separators = { left = "│", right = "│" },
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch", "diff" },
      lualine_c = { "filename" },
      lualine_x = { "encoding", "fileformat", "filetype" },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    },
  })
''
