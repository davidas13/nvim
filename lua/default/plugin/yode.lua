-- Installation ------------------------------------------------------------ {{{
local specs = require "specs"

vim.pack.add {
    specs["yode-nvim"],
}
-- }}}

-- Setup ------------------------------------------------------------------- {{{
-- NOTE: If error occurs during installation this plugin, run this snippet `git submodule update --init --recursive` in nvim-data to fixing.
require("yode-nvim").setup()

-- }}}

-- Setup Keybindings ------------------------------------------------------- {{{
vim.keymap.set(
    { "v", "x" },
    "<Leader>yc",
    ":YodeCreateSeditorFloating<CR>",
    { noremap = true, silent = true, desc = "Create Editor Floating" }
)

vim.keymap.set({ "v", "x" }, "<Leader>yr", function()
    vim.cmd "tab split"
    vim.cmd "normal! gv"
    vim.cmd "tab YodeCreateSeditorReplace"
end, { noremap = true, silent = true, desc = "Create Editor Replace" })

vim.keymap.set(
    { "n" },
    "<Leader>yd",
    ":YodeBufferDelete<CR>",
    { noremap = true, silent = true, desc = "Delete Buffer" }
)

vim.keymap.set(
    { "i" },
    "<Leader>yd",
    ":<Esc>YodeBufferDelete",
    { noremap = true, silent = true, desc = "Delete Buffer" }
)

vim.keymap.set(
    { "n" },
    "<C-W>r",
    ":YodeLayoutShiftWinDown<CR>",
    { noremap = true, silent = true, desc = "Shift Window Down" }
)

vim.keymap.set(
    { "n" },
    "<C-W>R",
    ":YodeLayoutShiftWinUp<CR>",
    { noremap = true, silent = true, desc = "Shift Window Up" }
)

vim.keymap.set(
    { "n" },
    "<C-W>J",
    ":YodeLayoutShiftWinBottom<CR>", -- at the moment this is needed to have no gap for floating windows
    { noremap = true, silent = true, desc = "Shift Window Bottom" }
)

vim.keymap.set(
    { "n" },
    "<C-W>K",
    ":YodeLayoutShiftWinTop<CR>", -- at the moment this is needed to have no gap for floating windows
    { noremap = true, silent = true, desc = "Shift Window Top" }
)
-- }}}
