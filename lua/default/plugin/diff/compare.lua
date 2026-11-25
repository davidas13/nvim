local api = vim.api
local uv = vim.uv
local panel_module = require "default.plugin.diff.panel"

local M = {}

local FILES_EQUAL_CHUNK = 65536

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

local function file_buffer(path, writable, ft)
    local buf
    if vim.fn.filereadable(path) == 1 then
        buf = vim.fn.bufadd(path)
        vim.fn.bufload(buf)
    else
        buf = api.nvim_create_buf(false, true)
        set_lines(buf, "")
    end
    if not buf or buf == 0 or not api.nvim_buf_is_valid(buf) then
        return nil
    end
    vim.bo[buf].bufhidden = "hide"
    vim.bo[buf].modifiable = writable
    vim.bo[buf].readonly = not writable
    if ft ~= "" and vim.bo[buf].filetype == "" then
        vim.bo[buf].filetype = ft
    end
    return buf
end

local function enable_diff(wins)
    for _, win in ipairs(wins) do
        if api.nvim_win_is_valid(win) and not vim.wo[win].diff then
            api.nvim_win_call(win, function()
                vim.cmd.diffthis()
            end)
        end
    end
end

function M.files(left, right)
    local ft = vim.filetype.match { filename = left } or ""
    local left_buf = file_buffer(left, false, ft)
    local right_buf = file_buffer(right, false, ft)
    if not left_buf or not right_buf then
        return nil
    end
    vim.cmd.tabnew()
    local tab = api.nvim_get_current_tabpage()
    local left_win = api.nvim_get_current_win()
    api.nvim_win_set_buf(left_win, left_buf)
    vim.cmd.vsplit()
    local right_win = api.nvim_get_current_win()
    api.nvim_win_set_buf(right_win, right_buf)
    local wins = { left_win, right_win }
    enable_diff(wins)
    return { tab = tab, wins = wins, left_buf = left_buf, right_buf = right_buf }
end

local function files_under(root)
    local found = {}
    local function walk(dir, prefix)
        local handle = uv.fs_scandir(dir)
        if not handle then
            return
        end
        while true do
            local name, kind = uv.fs_scandir_next(handle)
            if not name then
                break
            end
            local path = dir .. "/" .. name
            local rel = prefix == "" and name or prefix .. "/" .. name
            if not kind then
                local stat = uv.fs_stat(path)
                kind = stat and stat.type
            end
            if kind == "directory" then
                walk(path, rel)
            elseif kind == "file" or kind == "link" then
                found[rel] = true
            end
        end
    end
    walk(root, "")
    return found
end

local function is_binary(path)
    local fd = uv.fs_open(path, "r", 0)
    if not fd then
        return false
    end
    local chunk = uv.fs_read(fd, 8192) or ""
    uv.fs_close(fd)
    return chunk:find("\0", 1, true) ~= nil
end

local function files_equal(a, b)
    local stat_a = uv.fs_stat(a)
    local stat_b = uv.fs_stat(b)
    if stat_a and stat_b and stat_a.size ~= stat_b.size then
        return false
    end
    local fd_a = uv.fs_open(a, "r", 0)
    if not fd_a then
        return false
    end
    local fd_b = uv.fs_open(b, "r", 0)
    if not fd_b then
        uv.fs_close(fd_a)
        return false
    end
    local equal = true
    while true do
        local chunk_a = uv.fs_read(fd_a, FILES_EQUAL_CHUNK) or ""
        local chunk_b = uv.fs_read(fd_b, FILES_EQUAL_CHUNK) or ""
        if chunk_a ~= chunk_b then
            equal = false
            break
        end
        if chunk_a == "" then
            break
        end
    end
    uv.fs_close(fd_a)
    uv.fs_close(fd_b)
    return equal
end

local function dir_entries(left, right)
    local left_set = files_under(left)
    local right_set = files_under(right)
    local diffs = {}
    for rel in pairs(left_set) do
        if right_set[rel] then
            if not files_equal(left .. "/" .. rel, right .. "/" .. rel) then
                diffs[rel] = "M"
            end
        else
            diffs[rel] = "D"
        end
    end
    for rel in pairs(right_set) do
        if not left_set[rel] then
            diffs[rel] = "A"
        end
    end
    local entries = {}
    for rel, status in pairs(diffs) do
        table.insert(
            entries,
            { file = rel, status = status, label = status .. "  " .. rel }
        )
    end
    table.sort(entries, function(a, b)
        return a.file < b.file
    end)
    return entries
end

local function scratch(text, ft)
    local buf = api.nvim_create_buf(false, true)
    set_lines(buf, text)
    vim.bo[buf].bufhidden = "hide"
    vim.bo[buf].readonly = true
    vim.bo[buf].modifiable = false
    if ft and ft ~= "" then
        vim.bo[buf].filetype = ft
    end
    return buf
end

function M.dirs(left, right, width, page_size)
    local abs_left = vim.fn.fnamemodify(left, ":p")
    local abs_right = vim.fn.fnamemodify(right, ":p")
    local entries = dir_entries(abs_left, abs_right)
    if #entries == 0 then
        vim.notify(
            "Diff: no differences between directories",
            vim.log.levels.INFO
        )
        return nil
    end

    vim.cmd.tabnew()
    local tab = api.nvim_get_current_tabpage()
    local right_win = api.nvim_get_current_win()
    local right_buf = scratch ""
    api.nvim_win_set_buf(right_win, right_buf)
    vim.cmd.vsplit()
    local left_win = api.nvim_get_current_win()
    local left_buf = scratch ""
    api.nvim_win_set_buf(left_win, left_buf)

    local session = {
        tab = tab,
        wins = { left_win, right_win },
        left = abs_left,
        right = abs_right,
        left_bufs = {},
        right_bufs = {},
        current_rel = nil,
        panel = nil,
    }
    local pending = 0
    api.nvim_set_current_win(left_win)
    session.panel = panel_module.create(
        entries,
        function(_, entry)
            pending = pending + 1
            local token = pending
            vim.defer_fn(function()
                if token == pending and api.nvim_tabpage_is_valid(tab) then
                    M.show_dir(session, entry.file)
                end
            end, 30)
        end,
        nil,
        {
            listing_style = "list",
            width = width or 40,
            page_size = page_size or 100,
            cwd = abs_left,
        }
    )
    session.panel.session = session
    M.show_dir(session, entries[1].file)
    api.nvim_set_current_win(session.panel.win)
    return session
end

function M.show_dir(session, rel)
    if not rel or rel == session.current_rel then
        return
    end
    if not api.nvim_tabpage_is_valid(session.tab) then
        return
    end
    local left_path = session.left .. "/" .. rel
    local right_path = session.right .. "/" .. rel
    local ft = vim.filetype.match { filename = left_path }
        or vim.filetype.match { filename = right_path }
        or ""

    local binary = is_binary(left_path) or is_binary(right_path)
    local left_buf = session.left_bufs[rel]
    if not left_buf or not api.nvim_buf_is_valid(left_buf) then
        if binary then
            left_buf = scratch("[binary] " .. rel .. " (left)", ft)
        else
            left_buf = file_buffer(left_path, true, ft)
        end
        session.left_bufs[rel] = left_buf
    end
    local right_buf = session.right_bufs[rel]
    if not right_buf or not api.nvim_buf_is_valid(right_buf) then
        if binary then
            right_buf = scratch("[binary] " .. rel .. " (right)", ft)
        else
            right_buf = file_buffer(right_path, true, ft)
        end
        session.right_bufs[rel] = right_buf
    end
    if not left_buf or not right_buf then
        return
    end

    if api.nvim_win_is_valid(session.wins[1]) then
        api.nvim_win_call(session.wins[1], function()
            vim.cmd "diffoff!"
        end)
    end
    if api.nvim_win_is_valid(session.wins[1]) then
        api.nvim_win_set_buf(session.wins[1], left_buf)
    end
    if api.nvim_win_is_valid(session.wins[2]) then
        api.nvim_win_set_buf(session.wins[2], right_buf)
    end
    enable_diff(session.wins)
    session.current_rel = rel
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
