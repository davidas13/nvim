local M = {}

function M.unified(before, after, before_label, after_label)
    local result =
        vim.diff(before, after, { result_type = "unified", ctxlen = 3 })
    local lines = {
        "--- " .. (before_label or "before"),
        "+++ " .. (after_label or "after"),
    }
    if type(result) == "string" then
        table.insert(lines, result)
    else
        vim.list_extend(lines, result or {})
    end
    return table.concat(lines, "\n")
end

function M.open_vimdiff(before, after)
    vim.cmd "tabnew"
    local tab = vim.api.nvim_get_current_tabpage()
    local left = vim.api.nvim_create_buf(false, true)
    local right = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(
        left,
        0,
        -1,
        false,
        vim.split(before, "\n", { plain = true })
    )
    vim.api.nvim_buf_set_lines(
        right,
        0,
        -1,
        false,
        vim.split(after, "\n", { plain = true })
    )
    vim.api.nvim_set_current_buf(left)
    vim.wo.diff = true
    vim.cmd "vsplit"
    vim.api.nvim_set_current_buf(right)
    vim.wo.diff = true
    vim.cmd "diffupdate"
    return tab
end

return M
