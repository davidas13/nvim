-- Installation ------------------------------------------------------------ {{{
local specs = require "specs"

vim.pack.add {
    specs["nui.nvim"],
    specs["neovim-tips"],
}
-- }}}

-- Setup ------------------------------------------------------------------- {{{
require("neovim_tips").setup {
    daily_tip = 0,
}
-- }}}

-- Setup Keybindings ------------------------------------------------------- {{{
vim.keymap.set("n", "<Leader>ho", ":NeovimTips<CR>", { noremap = true, silent = true, desc = "Neovim Tips" })

vim.keymap.set("n", "<Leader>hr", ":NeovimTipsRandom<CR>", { noremap = true, silent = true, desc = "Show Random Tip" })

vim.keymap.set("n", "<Leader>he", ":NeovimTipsEdit<CR>", { noremap = true, silent = true, desc = "Edit Your Tips" })

vim.keymap.set("n", "<Leader>ha", ":NeovimTipsAdd<CR>", { noremap = true, silent = true, desc = "Add Your Tip" })

vim.keymap.set("n", "<Leader>hp", ":NeovimTipsPdf<CR>", { noremap = true, silent = true, desc = "Open Tips PDF" })
-- }}}
