-- Setup ------------------------------------------------------------------- {{{
vim.keymap.set({ "n" }, "<leader>pa", function()
    vim.cmd [[:tabnew]]
end, { noremap = true, silent = true, desc = "New Tab" })

vim.keymap.set({ "n" }, "<leader>pr", function()
    vim.ui.input({ prompt = "Rename Tab: " }, function(input)
        vim.cmd("TabRename " .. input)
    end)
end, { noremap = true, silent = true, desc = "Rename Tab" })

vim.keymap.set({ "n" }, "<leader>pc", function()
    vim.cmd [[:tabclose]]
end, { noremap = true, silent = true, desc = "Close Tab" })

vim.keymap.set({ "n" }, "<leader>po", function()
    vim.cmd [[:tabonly]]
end, { noremap = true, silent = true, desc = "Close Tab" })

vim.keymap.set({ "n" }, "<leader>pn", function()
    vim.cmd [[:tabn]]
end, { noremap = true, silent = true, desc = "Next Tab" })

vim.keymap.set({ "n" }, "<leader>pp", function()
    vim.cmd [[:tabp]]
end, { noremap = true, silent = true, desc = "Previous Tab" })

vim.keymap.set({ "n" }, "<leader>pmp", function()
    vim.cmd [[:-tabmove]]
end, { noremap = true, silent = true, desc = "Move Tab to Previous Position" })

vim.keymap.set({ "n" }, "<leader>pmn", function()
    vim.cmd [[:+tabmove]]
end, { noremap = true, silent = true, desc = "Move Tab to Next Position" })

vim.keymap.set({ "n" }, "]g", function()
    vim.cmd [[:tabn]]
end, { noremap = true, silent = true, desc = "Next Tab" })

vim.keymap.set({ "n" }, "[g", function()
    vim.cmd [[:tabp]]
end, { noremap = true, silent = true, desc = "Previous Tab" })
-- }}}
