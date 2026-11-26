local api = vim.api

local M = {}

local GLYPHS = {
    unicode = {
        branch = "├── ",
        last = "└── ",
        vertical = "│   ",
        blank = "    ",
    },
    ascii = {
        branch = "+-- ",
        last = "`-- ",
        vertical = "|   ",
        blank = "    ",
    },
}

local function build_tree(entries, cwd)
    local root = { dirs = {}, files = {} }
    for _, entry in ipairs(entries) do
        local rel = entry.rel or vim.fs.relpath(cwd, entry.file) or entry.file
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

local function flatten(node, prefix, glyphs, out)
    local children = {}
    for name, child in pairs(node.dirs) do
        table.insert(children, { name = name, kind = "dir", node = child })
    end
    for name, entry in pairs(node.files) do
        table.insert(children, { name = name, kind = "file", entry = entry })
    end
    table.sort(children, function(a, b)
        if a.kind ~= b.kind then
            return a.kind == "dir"
        end
        return a.name < b.name
    end)

    for i, child in ipairs(children) do
        local is_last = i == #children
        local connector = is_last and glyphs.last or glyphs.branch
        if child.kind == "dir" then
            table.insert(out, {
                kind = "dir",
                node = child.node,
                label = prefix .. connector .. child.name .. "/",
            })
            if child.node.open then
                local child_prefix = prefix
                    .. (is_last and glyphs.blank or glyphs.vertical)
                flatten(child.node, child_prefix, glyphs, out)
            end
        else
            table.insert(out, {
                kind = "file",
                file = child.entry.file,
                entry = child.entry,
                label = prefix
                    .. connector
                    .. child.entry.status
                    .. "  "
                    .. child.name,
            })
        end
    end
end

function M.create(entries, on_select, on_cycle, opts)
    opts = opts or {}
    vim.cmd "topleft vsplit"
    local win = api.nvim_get_current_win()
    local buf = api.nvim_create_buf(false, true)
    api.nvim_win_set_buf(win, buf)
    vim.wo[win].winfixbuf = true
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
        all_items = {},
        view_items = {},
        tree = nil,
        autocmd = nil,
        style = opts.listing_style or "list",
        tree_style = opts.tree_style or "unicode",
        cwd = opts.cwd or vim.fn.getcwd(),
        page_size = opts.page_size or 100,
        page = 1,
        page_count = 1,
    }

    local function select_item(item)
        if not item then
            return
        end
        if item.kind == "dir" then
            if opts.on_dir then
                opts.on_dir(item)
            end
            return
        end
        if on_select then
            on_select(item.file, item.entry)
        end
    end

    local function render_page()
        local all = panel.all_items
        if panel.page_size > 0 then
            panel.page_count = math.max(1, math.ceil(#all / panel.page_size))
            panel.page = math.min(math.max(1, panel.page), panel.page_count)
            local start = (panel.page - 1) * panel.page_size + 1
            local finish = math.min(start + panel.page_size - 1, #all)
            panel.view_items = {}
            for i = start, finish do
                table.insert(panel.view_items, all[i])
            end
            vim.wo[win].winbar = (" Page %d/%d (%d per page) | root: %s"):format(
                panel.page,
                panel.page_count,
                panel.page_size,
                vim.fn.fnamemodify(panel.cwd, ":~:.")
            )
        else
            panel.page_count = 1
            panel.page = 1
            panel.view_items = all
            vim.wo[win].winbar = ""
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

    local function refresh(new_entries)
        local reuse_tree = panel.style == "tree"
            and panel.tree
            and new_entries == panel.entries
        panel.entries = new_entries or {}
        panel.all_items = {}
        if panel.style == "tree" then
            if not reuse_tree then
                panel.tree = build_tree(panel.entries, panel.cwd)
            end
            flatten(
                panel.tree,
                "",
                GLYPHS[panel.tree_style] or GLYPHS.unicode,
                panel.all_items
            )
        else
            for _, entry in ipairs(panel.entries) do
                table.insert(panel.all_items, {
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
        render_page()
    end

    local function set_page(page, suppress_select)
        if panel.page_size <= 0 then
            return
        end
        panel.page = math.min(math.max(1, page), panel.page_count)
        render_page()
        if api.nvim_win_is_valid(win) then
            api.nvim_win_set_cursor(win, { 1, 0 })
        end
        if not suppress_select then
            for _, item in ipairs(panel.view_items) do
                if item.kind == "file" then
                    select_item(item)
                    break
                end
            end
        end
    end

    local function global_index()
        if not api.nvim_win_is_valid(win) then
            return 1
        end
        local row = api.nvim_win_get_cursor(win)[1]
        if panel.page_size <= 0 then
            return row
        end
        return (panel.page - 1) * panel.page_size + row
    end

    local function select_global(index)
        local total = #panel.all_items
        if total == 0 then
            return
        end
        index = ((index - 1) % total) + 1
        local item = panel.all_items[index]
        local target_page, row
        if panel.page_size <= 0 then
            target_page, row = 1, index
        else
            target_page = math.floor((index - 1) / panel.page_size) + 1
            row = ((index - 1) % panel.page_size) + 1
        end
        if target_page ~= panel.page then
            set_page(target_page, true)
        end
        if api.nvim_win_is_valid(win) then
            api.nvim_win_set_cursor(win, { row, 0 })
        end
        select_item(item)
    end

    local function step_file(step)
        local total = #panel.all_items
        if total == 0 then
            return
        end
        local index = global_index()
        for offset = 1, total do
            local candidate = ((index + step * offset - 1) % total) + 1
            if panel.all_items[candidate].kind == "file" then
                select_global(candidate)
                return
            end
        end
    end

    refresh(entries)

    panel.autocmd = api.nvim_create_autocmd("CursorMoved", {
        buffer = buf,
        callback = function()
            if not api.nvim_win_is_valid(win) then
                return
            end
            local row = api.nvim_win_get_cursor(win)[1]
            select_item(panel.view_items[row])
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
                    panel.page = 1
                    render_page()
                end
            end,
            desc = "Toggle folder",
        })
    end

    if opts.on_swap then
        api.nvim_buf_set_keymap(buf, "n", "s", "", {
            callback = opts.on_swap,
            desc = "Swap compared directories",
        })
    end

    api.nvim_buf_set_keymap(buf, "n", "]p", "", {
        callback = function()
            set_page(panel.page + 1)
        end,
        desc = "Next page",
    })
    api.nvim_buf_set_keymap(buf, "n", "[p", "", {
        callback = function()
            set_page(panel.page - 1)
        end,
        desc = "Previous page",
    })

    function panel.refresh(new_entries)
        refresh(new_entries)
    end

    function panel.set_context(new_entries, cwd)
        panel.cwd = cwd or panel.cwd
        panel.tree = nil
        refresh(new_entries)
        panel.page = 1
        render_page()
    end

    function panel.set_page(page)
        set_page(page)
    end

    function panel.select_index(row)
        if not api.nvim_win_is_valid(win) then
            return
        end
        if row < 1 or row > #panel.view_items then
            return
        end
        api.nvim_win_set_cursor(win, { row, 0 })
        select_item(panel.view_items[row])
    end

    function panel.next_entry()
        step_file(1)
    end

    function panel.prev_entry()
        step_file(-1)
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
