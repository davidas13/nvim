local api = vim.api
local panel_module = require "default.plugin.diff.panel"

local M = {}

local function read(path)
    local handle = io.open(path, "rb")
    if not handle then
        return ""
    end
    local content = handle:read "*a"
    handle:close()
    return content or ""
end

local function set_lines(buf, text)
    api.nvim_buf_set_lines(
        buf,
        0,
        -1,
        false,
        vim.split(text, "\n", { plain = true })
    )
end

local function file_buffer(path)
    local buf = vim.fn.bufadd(path)
    vim.fn.bufload(buf)
    vim.bo[buf].bufhidden = "hide"
    vim.bo[buf].readonly = true
    vim.bo[buf].modifiable = false
    return buf
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
        api.nvim_win_call(win, function()
            vim.cmd "diffoff!"
        end)
    end
    for _, win in ipairs(wins) do
        api.nvim_win_call(win, function()
            vim.cmd.diffthis()
        end)
    end
end

local function update(buf, text)
    if not api.nvim_buf_is_valid(buf) then
        return
    end
    vim.bo[buf].modifiable = true
    vim.bo[buf].readonly = false
    set_lines(buf, text)
    vim.bo[buf].readonly = true
    vim.bo[buf].modifiable = false
end

function M.files(left, right)
    vim.cmd.tabnew()
    local tab = api.nvim_get_current_tabpage()
    local left_win = api.nvim_get_current_win()
    local left_buf = file_buffer(left)
    api.nvim_win_set_buf(left_win, left_buf)
    vim.cmd.vsplit()
    local right_win = api.nvim_get_current_win()
    local right_buf = file_buffer(right)
    api.nvim_win_set_buf(right_win, right_buf)
    local wins = { left_win, right_win }
    apply_diff(wins)
    return { tab = tab, wins = wins, left_buf = left_buf, right_buf = right_buf }
end

local function dir_entries(left, right)
    local paths = {}
    for _, root in ipairs { left, right } do
        for _, path in ipairs(vim.fn.glob(root .. "/**/*", true, true)) do
            if vim.fn.filereadable(path) == 1 then
                local rel = vim.fs.relpath(root, path)
                if rel then
                    paths[rel] = true
                end
            end
        end
    end
    local entries = {}
    for rel in pairs(paths) do
        table.insert(entries, { file = rel, status = "D", label = rel })
    end
    table.sort(entries, function(a, b)
        return a.file < b.file
    end)
    return entries
end

function M.dirs(left, right, width)
    vim.cmd.tabnew()
    local tab = api.nvim_get_current_tabpage()
    local right_win = api.nvim_get_current_win()
    local right_buf = snapshot ""
    api.nvim_win_set_buf(right_win, right_buf)
    vim.cmd.vsplit()
    local left_win = api.nvim_get_current_win()
    local left_buf = snapshot ""
    api.nvim_win_set_buf(left_win, left_buf)

    local session = {
        tab = tab,
        wins = { left_win, right_win },
        left_buf = left_buf,
        right_buf = right_buf,
        left = left,
        right = right,
    }
    api.nvim_set_current_win(left_win)
    session.panel = panel_module.create(
        dir_entries(left, right),
        function(_, entry)
            M.show_dir(session, entry.file)
        end,
        nil,
        { listing_style = "list", width = width or 40, cwd = left }
    )
    if session.panel.entries[1] then
        M.show_dir(session, session.panel.entries[1].file)
    end
    apply_diff(session.wins)
    api.nvim_set_current_win(session.panel.win)
    return session
end

function M.show_dir(session, rel)
    update(session.left_buf, read(session.left .. "/" .. rel))
    update(session.right_buf, read(session.right .. "/" .. rel))
    apply_diff(session.wins)
end

function M.equalize(session, panel_width)
    local width = math.max(12, math.floor((vim.o.columns - panel_width) / 2))
    for _, win in ipairs(session.wins) do
        if api.nvim_win_is_valid(win) then
            vim.wo[win].winfixwidth = true
            api.nvim_win_set_width(win, width)
        end
    end
end

return M
