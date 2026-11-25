local api = vim.api
local diff = require "default.plugin.diff.diff"

local M = {}

local function set_lines(buf, text)
    api.nvim_buf_set_lines(
        buf,
        0,
        -1,
        false,
        vim.split(text, "\n", { plain = true })
    )
end

local function snapshot(text)
    local buf = api.nvim_create_buf(false, true)
    set_lines(buf, text)
    vim.bo[buf].readonly = true
    vim.bo[buf].modifiable = false
    return buf
end

local function apply_diff(wins)
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

function M.create(file, sides)
    vim.cmd.tabnew()
    local tab = api.nvim_get_current_tabpage()
    local ours_win = api.nvim_get_current_win()
    local ours_buf = vim.fn.bufadd(file)
    vim.fn.bufload(ours_buf)
    vim.bo[ours_buf].bufhidden = "hide"
    diff.set_win_buf(ours_win, ours_buf)
    set_lines(ours_buf, sides.ours)

    vim.cmd.vsplit()
    local base_win = api.nvim_get_current_win()
    local base_buf = snapshot(sides.base)
    diff.set_win_buf(base_win, base_buf)

    vim.cmd.vsplit()
    local theirs_win = api.nvim_get_current_win()
    local theirs_buf = snapshot(sides.theirs)
    diff.set_win_buf(theirs_win, theirs_buf)

    local merge = {
        tab = tab,
        wins = { ours_win, base_win, theirs_win },
        ours_buf = ours_buf,
        base_buf = base_buf,
        theirs_buf = theirs_buf,
    }
    diff.lock_wins(merge.wins)
    apply_diff(merge.wins)
    return merge
end

function M.show(merge, file, sides)
    if not api.nvim_buf_is_valid(merge.ours_buf) then
        return
    end
    set_lines(merge.ours_buf, sides.ours)
    for _, item in ipairs {
        { merge.base_buf, sides.base },
        { merge.theirs_buf, sides.theirs },
    } do
        if api.nvim_buf_is_valid(item[1]) then
            vim.bo[item[1]].modifiable = true
            vim.bo[item[1]].readonly = false
            set_lines(item[1], item[2])
            vim.bo[item[1]].readonly = true
            vim.bo[item[1]].modifiable = false
        end
    end
    apply_diff(merge.wins)
end

function M.equalize(merge, panel_width)
    local width = math.max(12, math.floor((vim.o.columns - panel_width) / 3))
    for _, win in ipairs(merge.wins) do
        if api.nvim_win_is_valid(win) then
            vim.wo[win].winfixwidth = true
            api.nvim_win_set_width(win, width)
        end
    end
end

return M
