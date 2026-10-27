-- Clear Highlights {{{
vim.keymap.set("n", "<space><esc>", function()
    vim.cmd "nohl"
end, { silent = true, desc = "Clear Highlight", noremap = true })
-- }}}

-- Buffers {{{
vim.keymap.set("n", "<leader>c", function()
    -- check if snacks plugin is installed
    if pcall(require, "snacks") then
        require("snacks").bufdelete()
    else
        vim.cmd "bdelete"
    end
end, { desc = "Close Buffer" })
-- }}}

-- Diagnostics {{{
vim.keymap.set("n", "[d", function()
    vim.diagnostic.jump { count = -1, float = true }
end, { desc = "Previous diagnostic" })

vim.keymap.set("n", "]d", function()
    vim.diagnostic.jump { count = 1, float = true }
end, { desc = "Next diagnostic" })
-- }}}

-- Window Navigation and Resizing {{{
vim.keymap.set("t", "<C-w>h", "<C-\\><C-n><C-w>h", { noremap = true, silent = true })
vim.keymap.set("t", "<C-w>j", "<C-\\><C-n><C-w>j", { noremap = true, silent = true })
vim.keymap.set("t", "<C-w>k", "<C-\\><C-n><C-w>k", { noremap = true, silent = true })
vim.keymap.set("t", "<C-w>l", "<C-\\><C-n><C-w>l", { noremap = true, silent = true })

vim.keymap.set("t", "<C-Up>", "<C-\\><C-n>:resize +2<CR>", { noremap = true, silent = true })
vim.keymap.set("t", "<C-Down>", "<C-\\><C-n>:resize -2<CR>", { noremap = true, silent = true })
vim.keymap.set("t", "<C-Left>", "<C-\\><C-n>:vertical resize -2<CR>", { noremap = true, silent = true })
vim.keymap.set("t", "<C-Right>", "<C-\\><C-n>:vertical resize +2<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<C-Up>", ":resize +2<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<C-Down>", ":resize -2<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", { noremap = true, silent = true })
-- }}}

-- Plugin Keymaps {{{
-- Update plugins
vim.keymap.set({ "n" }, "<leader>:xu", vim.pack.update, { desc = "Update Plugins" })
-- }}}

-- Editor Keymaps {{{
-- Restart neovim.
vim.keymap.set("n", "<leader>:r", function()
    vim.cmd "restart"
end, { desc = "Restart" })

-- Remove buffers.
vim.keymap.set("n", "<leader>:bd", function()
    vim.cmd "bdelete"
end, { desc = "Buffer Delete" })

vim.keymap.set("n", "<leader>:bw", function()
    vim.cmd "bwipeout"
end, { desc = "Buffer Wipeout" })

-- Copy relative path to clipboard (e.g., src/main.js)
vim.keymap.set("n", "<leader>cf", function()
    vim.fn.setreg("+", vim.fn.expand "%")
    print "Copied relative path"
end, { desc = "Copy Relative Filepath" })

-- Copy absolute path to clipboard (e.g., /home/user/project/src/main.js)
vim.keymap.set("n", "<leader>cF", function()
    vim.fn.setreg("+", vim.fn.expand "%:p")
    print "Copied absolute path"
end, { desc = "Copy Absolute Filepath" })

-- Copy filename only (e.g., main.js)
vim.keymap.set("n", "<leader>cn", function()
    vim.fn.setreg("+", vim.fn.expand "%:t")
    print "Copied filename"
end, { desc = "Copy Filename" })
-- }}}

-- NetRW Keymaps {{{
-- TODO: Complete a custom keymap for netrw.
vim.api.nvim_create_augroup("netrw_mappings", {
    clear = true,
})

vim.api.nvim_create_autocmd("FileType", {
    pattern = "netrw",
    group = "netrw_mappings",
    callback = function()
        vim.keymap.set("n", "<Esc>", "<C-w>z")
    end,
})
-- }}}
