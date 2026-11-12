-- Setup Keybindings ------------------------------------------------------- {{{
local seditors = {}
local open_count = 0

-- A visual selection reports its mode through mode() while the keymap runs,
-- and through visualmode() afterwards. Linewise is the safe fallback.
local function selection_type()
    local mode = vim.fn.mode()
    if mode == "v" or mode == "V" or mode == "\22" then
        return mode
    end
    local visual = vim.fn.visualmode()
    if visual ~= "" then
        return visual
    end
    return "V"
end

-- Saving the seditor replaces the selected range in the source buffer. The
-- source file on disk stays untouched, so the user saves it as usual.
local function write_back(bufnr)
    local sed = seditors[bufnr]
    if not sed or not vim.api.nvim_buf_is_valid(sed.file_bufnr) then
        return
    end
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    vim.api.nvim_buf_set_lines(
        sed.file_bufnr,
        sed.firstline,
        sed.lastline,
        false,
        lines
    )
    sed.lastline = sed.firstline + #lines
    vim.bo[sed.file_bufnr].modified = true
    vim.bo[bufnr].modified = false
end

local function open_selection(command)
    local lines = vim.fn.getregion(
        vim.fn.getpos "v",
        vim.fn.getpos ".",
        { type = selection_type() }
    )
    local file_bufnr = vim.api.nvim_get_current_buf()
    local path = vim.api.nvim_buf_get_name(file_bufnr)
    local filetype = vim.bo[file_bufnr].filetype
    local firstline = math.min(vim.fn.getpos("v")[2], vim.fn.getpos(".")[2])
    local lastline = math.max(vim.fn.getpos("v")[2], vim.fn.getpos(".")[2])

    vim.cmd(command)
    local buf = vim.api.nvim_create_buf(true, false)

    -- The native lsp attach callback starts servers for buffers with an empty
    -- buftype only, and root detection needs a real path, so the seditor keeps
    -- a path inside the source directory and routes :w to BufWriteCmd.
    open_count = open_count + 1
    vim.api.nvim_buf_set_name(buf, ("%s.seditor.%d"):format(path, open_count))
    vim.bo[buf].filetype = filetype
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false

    vim.api.nvim_win_set_buf(0, buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    seditors[buf] = {
        file_bufnr = file_bufnr,
        firstline = firstline - 1,
        lastline = lastline,
    }
    vim.api.nvim_create_autocmd({ "BufWriteCmd", "BufWipeout" }, {
        buffer = buf,
        callback = function(args)
            if args.event == "BufWriteCmd" then
                write_back(buf)
            else
                seditors[buf] = nil
            end
        end,
    })
    vim.bo[buf].modified = false
    return buf
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
