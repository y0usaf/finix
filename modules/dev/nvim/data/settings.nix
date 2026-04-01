# Core Neovim settings - shared across all systems
# Returns Lua code for vim.opt configurations
''
  -- Line numbers and UI
  vim.opt.number = true
  vim.opt.relativenumber = true
  vim.opt.signcolumn = "yes"
  vim.opt.wrap = true
  vim.opt.linebreak = true
  vim.opt.breakindent = true
  vim.opt.showbreak = "↪ "
  vim.opt.termguicolors = true
  vim.opt.scrolloff = 8
  vim.opt.sidescrolloff = 8
  vim.opt.cursorline = true
  vim.opt.pumheight = 15
  vim.opt.showmode = false
  vim.opt.laststatus = 2
  vim.opt.cmdheight = 1

  -- Indentation
  vim.opt.expandtab = true
  vim.opt.tabstop = 2
  vim.opt.shiftwidth = 2

  -- System integration
  vim.opt.clipboard = "unnamedplus"
  vim.opt.mouse = "a"

  -- Search
  vim.opt.ignorecase = true
  vim.opt.smartcase = true

  -- Timing
  vim.opt.updatetime = 250
  vim.opt.timeoutlen = 300

  -- Splits
  vim.opt.splitbelow = true
  vim.opt.splitright = true
  vim.opt.splitkeep = "screen"
  vim.opt.virtualedit = "onemore"

  -- Additional UI options
  vim.opt.shortmess:append({ W = true, I = true, c = true, C = true })
  vim.opt.fillchars = { eob = " ", fold = " ", foldsep = " ", diff = "/" }
  vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

  -- Disable netrw for neo-tree
  vim.g.loaded_netrw = 1
  vim.g.loaded_netrwPlugin = 1

  -- UFO folding settings
  vim.opt.foldcolumn = "1"
  vim.opt.foldlevel = 99
  vim.opt.foldlevelstart = 99
  vim.opt.foldenable = true
''
