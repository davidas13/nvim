vim.g.mapleader = " "
vim.g.localleader = ","

-- Use system clipboard.
vim.opt.clipboard = "unnamed,unnamedplus"
vim.opt.completeopt = { "menu", "menuone", "noselect" }
-- Allow use the mouse in Nvim.
vim.opt.mouse = "a"

-- Tab
-- Number of visual spaces per Tab.
vim.opt.tabstop = 4
-- Number of spacein tab when editing.
vim.opt.softtabstop = 4
-- Insert 4 spaces on a tab.
vim.opt.shiftwidth = 4
-- tabs are spaces.
vim.opt.expandtab = true

-- UI
-- Show absolute number.
vim.opt.number = true
-- Add numbers to each line on the left side.
vim.opt.relativenumber = true
-- Highlight cursor cursor line underneath the cursor horizontally.
vim.opt.cursorline = true
-- Open new vertical split bottom.
vim.opt.splitbelow = true
-- Open new horizontal split right.
vim.opt.splitright = true
-- Show mode.
vim.opt.showmode = true

-- Search text
-- Search as characters are entered.
vim.opt.incsearch = true
-- Show highlight matches.
vim.opt.hlsearch = true
-- Ignore case in dearches by default.
vim.opt.ignorecase = true
-- Make case sensitive if an uppercase is entered.
vim.opt.smartcase = true

vim.opt.termguicolors = true
vim.opt.scrolloff = 10
vim.opt.autoindent = true

vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.list = true
vim.opt.listchars:append {
    extends = "·",
    precedes = "·",
    -- nbsp = "␣",
    nbsp = "+",
    tab = "> ",
    -- eol = "↴",
    multispace = "·",
    lead = "·",
    -- trail = "-",
    trail = "·",
}

-- Set to 3 so that the statusline always on bottom and full width.
-- References:
-- - https://www.reddit.com/r/neovim/comments/x1lp0l/comment/imeb8s3/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
vim.opt.laststatus = 3
vim.opt.signcolumn = "yes"
vim.opt.numberwidth = 4

vim.diagnostic.config {
    virtual_text = false, -- show inline messages
    signs = true, -- show signs in the gutter
    underline = true, -- underline problematic text
    update_in_insert = false, -- don't update diagnostics while typing
    severity_sort = true, -- sort diagnostics by severity
}

vim.o.background = "dark"
-- Show the cursor position.
vim.o.splitkeep = "screen"
vim.o.undofile = true
vim.o.undolevels = 1000000
vim.o.timeoutlen = 400
-- vim.o.colorcolumn = "79,110"
vim.o.fileformat = "unix"
vim.o.showtabline = 2
vim.o.sessionoptions = "blank,buffers,curdir,folds,globals,help,tabpages,terminal,winsize,winpos,localoptions"
vim.o.autoread = true
vim.opt.updatetime = 300
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.breakindent = true

-- vim.g.loaded_netrw = 1
-- vim.g.loaded_netrwPlugin = 1
vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 0
vim.g.netrw_keepdir = 0
vim.g.netrw_altv = 1
vim.g.netrw_winsize = 15
vim.g.netrw_browse_split = 4

-- Check if ripgrep is installed.
if vim.fn.executable "rg" then
    vim.opt.grepprg = "rg --vimgrep --no-heading --smart-case"
    vim.opt.grepformat = "%f:%l:%c:%m,%f:%l:%m"
end
