-- Setup Keybindings ------------------------------------------------------- {{{
local function open_selection(command)
    local lines = vim.fn.getregion(
        vim.fn.getpos "v",
        vim.fn.getpos ".",
        { type = vim.fn.visualmode() }
    )
    local source = vim.api.nvim_get_current_buf()
    local path = vim.api.nvim_buf_get_name(source)
    local filetype = vim.bo[source].filetype

    vim.cmd(command)
    local buf = vim.api.nvim_create_buf(true, false)

    -- lspconfig skips unnamed buffers and buffers with buftype nofile when it
    -- attaches servers, so the copy keeps a path inside the source directory.
    vim.api.nvim_buf_set_name(buf, path .. ".seditor")
    vim.bo[buf].filetype = filetype
    vim.bo[buf].swapfile = false
    vim.bo[buf].bufhidden = "wipe"

    vim.api.nvim_win_set_buf(0, buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modified = false
end

vim.keymap.set({ "v", "x" }, "<Leader>yt", function()
    open_selection "tabnew"
end, { desc = "Open Selection in New Tab" })

vim.keymap.set({ "v", "x" }, "<Leader>ys", function()
    open_selection "new"
end, { desc = "Open Selection in Horizontal Split" })

vim.keymap.set({ "v", "x" }, "<Leader>yv", function()
    open_selection "vnew"
end, { desc = "Open Selection in Vertical Split" })
-- }}}
