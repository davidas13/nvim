-- Setup ------------------------------------------------------------------- {{{
-- Copy references and unified diffs. The public surface and its keybindings
-- live here, the mechanics stay in the sibling modules.

local location = require "default.plugin.copy.location"
local copy_diff = require "default.plugin.copy.diff"

local M = {}

M.pick = location.pick
M.copy = location.copy
M.copy_diff = copy_diff.copy
M.clear_diff = copy_diff.clear

-- Copy Reference {{{
-- Every path, scope, and line combination for the cursor position. A visual
-- selection over more than one line turns the line number into a range.
vim.keymap.set({ "n", "x", "v" }, "<C-y>", M.pick, {
    silent = true,
    desc = "Copy Reference Picker",
    noremap = true,
})

-- One-shot copies that skip the picker.
vim.keymap.set("n", "<leader>cf", function()
    M.copy "rel"
end, { silent = true, desc = "Copy Relative Filepath", noremap = true })

vim.keymap.set("n", "<leader>cF", function()
    M.copy "abs"
end, { silent = true, desc = "Copy Absolute Filepath", noremap = true })

vim.keymap.set("n", "<leader>cn", function()
    M.copy "base"
end, { silent = true, desc = "Copy Filename", noremap = true })
-- }}}

vim.api.nvim_create_user_command("CopyDiff", M.copy_diff, {})
vim.api.nvim_create_user_command("CopyDiffClear", M.clear_diff, {})

return M
-- }}}
