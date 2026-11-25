local api = vim.api

local M = {}

local function build_tree(entries, cwd)
    local root = { dirs = {}, files = {} }
    for _, entry in ipairs(entries) do
        local rel = vim.fs.relpath(cwd, entry.file) or entry.file
        local parts = vim.split(rel, "/", { plain = true })
        local node = root
        for i = 1, #parts - 1 do
            local name = parts[i]
            node.dirs[name] = node.dirs[name]
                or { dirs = {}, files = {}, open = true, name = name }
            node = node.dirs[name]
        end
        node.files[parts[#parts]] = entry
    end
    return root
end

local function flatten(node, depth, out)
    local dirs = vim.tbl_keys(node.dirs)
    table.sort(dirs)
    for _, name in ipairs(dirs) do
        local child = node.dirs[name]
        table.insert(out, {
            kind = "dir",
            node = child,
            label = string.rep("  ", depth)
                .. (child.open and "- " or "+ ")
                .. name,
        })
        if child.open then
            flatten(child, depth + 1, out)
        end
    end
    local files = vim.tbl_keys(node.files)
    table.sort(files)
    for _, name in ipairs(files) do
        local entry = node.files[name]
        table.insert(out, {
            kind = "file",
            file = entry.file,
            entry = entry,
            label = string.rep("  ", depth) .. entry.status .. "  " .. name,
        })
    end
end

function M.create(entries, on_select, on_cycle, opts)
    opts = opts or {}
    vim.cmd "topleft vsplit"
    local win = api.nvim_get_current_win()
    local buf = api.nvim_create_buf(false, true)
    api.nvim_win_set_buf(win, buf)
    vim.wo[win].diff = false
    vim.wo[win].scrollbind = false
    vim.wo[win].cursorbind = false
    api.nvim_win_set_width(win, opts.width or 40)
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].modifiable = false
    vim.bo[buf].readonly = true

    local panel = {
        win = win,
        buf = buf,
        entries = {},
        view_items = {},
        tree = nil,
        autocmd = nil,
        style = opts.listing_style or "list",
        cwd = opts.cwd or vim.fn.getcwd(),
    }

    local function refresh(new_entries)
        local reuse_tree = panel.style == "tree"
            and panel.tree
            and new_entries == panel.entries
        panel.entries = new_entries or {}
        panel.view_items = {}
        if panel.style == "tree" then
            if not reuse_tree then
                panel.tree = build_tree(panel.entries, panel.cwd)
            end
            flatten(panel.tree, 0, panel.view_items)
        else
            for _, entry in ipairs(panel.entries) do
                table.insert(panel.view_items, {
                    kind = "file",
                    file = entry.file,
                    entry = entry,
                    label = entry.label
                        or entry.status
                            .. "  "
                            .. vim.fn.fnamemodify(entry.file, ":~:."),
                })
            end
        end
        local lines = {}
        for _, item in ipairs(panel.view_items) do
            table.insert(lines, item.label)
        end
        if #lines == 0 then
            table.insert(lines, "No changed files")
        end
        vim.bo[buf].modifiable = true
        vim.bo[buf].readonly = false
        api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.bo[buf].readonly = true
        vim.bo[buf].modifiable = false
    end

    refresh(entries)

    panel.autocmd = api.nvim_create_autocmd("CursorMoved", {
        buffer = buf,
        callback = function()
            if not api.nvim_win_is_valid(win) then
                return
            end
            local row = api.nvim_win_get_cursor(win)[1]
            local item = panel.view_items[row]
            if item and item.kind == "file" and on_select then
                on_select(item.file, item.entry)
            end
        end,
    })

    if on_cycle then
        api.nvim_buf_set_keymap(buf, "n", "<Tab>", "", {
            callback = on_cycle,
            desc = "Cycle diff profile",
        })
    end

    if panel.style == "tree" then
        api.nvim_buf_set_keymap(buf, "n", "<CR>", "", {
            callback = function()
                if not api.nvim_win_is_valid(win) then
                    return
                end
                local row = api.nvim_win_get_cursor(win)[1]
                local item = panel.view_items[row]
                if item and item.kind == "dir" then
                    item.node.open = not item.node.open
                    refresh(panel.entries)
                end
            end,
            desc = "Toggle folder",
        })
    end

    function panel.refresh(new_entries)
        refresh(new_entries)
    end

    function panel.select_index(row)
        if not api.nvim_win_is_valid(win) then
            return
        end
        if row < 1 or row > #panel.view_items then
            return
        end
        api.nvim_win_set_cursor(win, { row, 0 })
        local item = panel.view_items[row]
        if item and item.kind == "file" and on_select then
            on_select(item.file, item.entry)
        end
    end

    function panel.close()
        if panel.autocmd then
            api.nvim_del_autocmd(panel.autocmd)
            panel.autocmd = nil
        end
        if api.nvim_win_is_valid(win) then
            api.nvim_win_close(win, true)
        end
    end

    return panel
end

return M
