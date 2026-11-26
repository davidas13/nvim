local api = vim.api

local M = {}

function M.set_win_buf(win, buf)
    if not api.nvim_win_is_valid(win) then
        return
    end
    local fixed = vim.wo[win].winfixbuf
    vim.wo[win].winfixbuf = false
    api.nvim_win_set_buf(win, buf)
    vim.wo[win].winfixbuf = fixed
end

function M.lock_wins(wins)
    for _, win in ipairs(wins) do
        if api.nvim_win_is_valid(win) then
            vim.wo[win].winfixbuf = true
        end
    end
end

function M.apply_diff(wins)
    for _, win in ipairs(wins) do
        if api.nvim_win_is_valid(win) then
            api.nvim_win_call(win, function()
                vim.cmd "diffoff!"
            end)
        end
    end
    for _, win in ipairs(wins) do
        if api.nvim_win_is_valid(win) then
            api.nvim_win_call(win, function()
                vim.cmd.diffthis()
            end)
        end
    end
end

local function set_base_lines(buf, text)
    if not api.nvim_buf_is_valid(buf) then
        return
    end
    vim.bo[buf].modifiable = true
    vim.bo[buf].readonly = false
    local lines = vim.split(text or "", "\n", { plain = true })
    api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].readonly = true
    vim.bo[buf].modifiable = false
end

function M.create_pane()
    vim.cmd.tabnew()
    local tab = api.nvim_get_current_tabpage()
    local base_win = api.nvim_get_current_win()
    local base_buf = api.nvim_create_buf(false, true)
    M.set_win_buf(base_win, base_buf)
    vim.cmd.vsplit()
    local work_win = api.nvim_get_current_win()
    local work_buf = api.nvim_create_buf(false, true)
    M.set_win_buf(work_win, work_buf)
    vim.bo[base_buf].modifiable = false
    vim.bo[base_buf].readonly = true
    local empty_base_buf = api.nvim_create_buf(false, true)
    local empty_work_buf = api.nvim_create_buf(false, true)
    M.lock_wins { base_win, work_win }
    M.apply_diff { base_win, work_win }
    return {
        tab = tab,
        base_win = base_win,
        work_win = work_win,
        base_buf = base_buf,
        empty_base_buf = empty_base_buf,
        empty_work_buf = empty_work_buf,
    }
end

function M.clear(pane)
    if not api.nvim_tabpage_is_valid(pane.tab) then
        return
    end
    M.set_win_buf(pane.base_win, pane.empty_base_buf)
    M.set_win_buf(pane.work_win, pane.empty_work_buf)
    set_base_lines(pane.empty_base_buf, "")
    set_base_lines(pane.empty_work_buf, "")
    M.apply_diff { pane.base_win, pane.work_win }
end

function M.show_file(pane, file, before)
    if not api.nvim_tabpage_is_valid(pane.tab) then
        return nil
    end
    local work_buf = vim.fn.bufadd(file)
    if not work_buf or work_buf == 0 then
        return nil
    end
    vim.fn.bufload(work_buf)
    if not api.nvim_buf_is_valid(work_buf) then
        return nil
    end
    vim.bo[work_buf].bufhidden = "hide"
    M.set_win_buf(pane.work_win, work_buf)
    set_base_lines(pane.base_buf, before)
    local ft = vim.bo[work_buf].filetype
    if ft == "" then
        ft = vim.filetype.match { filename = file } or ""
    end
    if ft ~= "" then
        vim.bo[pane.base_buf].filetype = ft
    end
    M.apply_diff { pane.base_win, pane.work_win }
    return work_buf
end

function M.equalize_wins(base_win, work_win, panel_width)
    local width =
        math.max(20, math.floor((vim.o.columns - (panel_width or 40)) / 2))
    vim.wo[base_win].winfixwidth = true
    vim.wo[work_win].winfixwidth = true
    api.nvim_win_set_width(base_win, width)
    api.nvim_win_set_width(work_win, width)
end

return M
