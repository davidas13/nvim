local api = vim.api
local sources = require "default.plugin.diff.sources"
local diff = require "default.plugin.diff.diff"
local panel_module = require "default.plugin.diff.panel"
local merge_module = require "default.plugin.diff.merge"
local compare_module = require "default.plugin.diff.compare"
local picker_actions = require "snacks.picker.actions"

local M = {}

local original_picker_jump = picker_actions.jump

local function in_diff_tab()
    local tab = api.nvim_get_current_tabpage()
    return vim.fn.gettabvar(
        api.nvim_tabpage_get_number(tab),
        "diffexplorer_title",
        ""
    ) ~= ""
end

local function guarded_picker_jump(picker, item, action)
    if not in_diff_tab() then
        return original_picker_jump(picker, item, action)
    end
    local items = picker:selected { fallback = true }
    if #items == 0 then
        return
    end
    local selected = items[1]
    if not selected.file or selected.file == "" then
        return
    end
    picker:close()
    vim.cmd(("tabedit %s"):format(vim.fn.fnameescape(selected.file)))
    local pos = selected.pos
    if pos and pos[1] > 0 then
        api.nvim_win_set_cursor(0, { pos[1], pos[2] or 0 })
    end
end

picker_actions.jump = guarded_picker_jump

local DEFAULT_PROFILES = {
    working = { before = { vcs = "head" }, after = "worktree" },
    staged = { before = { vcs = "head" }, after = { vcs = "index" } },
    unstaged = { before = { vcs = "index" }, after = "worktree" },
}

local DEFAULT_REDIRECTS = {
    e = "tabedit",
    edit = "tabedit",
    sp = "tabedit",
    split = "tabedit",
    vs = "tabedit",
    vsplit = "tabedit",
    new = "tabnew",
    vnew = "tabnew",
}

local config = {
    default_profile = "working",
    profiles = {},
    listing_style = "tree", -- or list
    tree_style = "unicode", -- or ascii
    page_size = 100,
    panel_width = 40,
    tab_title = "Diff",
    history_tab_title = "DiffHistory",
    merge_tab_title = "DiffMerge",
    diff_files_tab_title = "DiffFiles",
    diff_dirs_tab_title = "DiffDirs",
    redirect_commands = {},
}

local views = {}

function M.setup(opts)
    opts = opts or {}
    config.default_profile = opts.default_profile or config.default_profile
    config.listing_style = opts.listing_style or config.listing_style
    config.tree_style = opts.tree_style or config.tree_style
    config.page_size = opts.page_size or config.page_size
    config.panel_width = opts.panel_width or config.panel_width
    config.tab_title = opts.tab_title or config.tab_title
    config.history_tab_title = opts.history_tab_title
        or config.history_tab_title
    config.merge_tab_title = opts.merge_tab_title or config.merge_tab_title
    config.diff_files_tab_title = opts.diff_files_tab_title
        or config.diff_files_tab_title
    config.diff_dirs_tab_title = opts.diff_dirs_tab_title
        or config.diff_dirs_tab_title
    config.redirect_commands = vim.tbl_deep_extend(
        "force",
        DEFAULT_REDIRECTS,
        opts.redirect_commands or {}
    )
    config.profiles =
        vim.tbl_deep_extend("force", DEFAULT_PROFILES, opts.profiles or {})
end

local function apply_project_config()
    local snapshot = vim.deepcopy(config)
    local path = vim.fn.fnamemodify(vim.fn.getcwd() .. "/.nvim.lua", ":p")
    if vim.fn.filereadable(path) ~= 1 then
        return snapshot
    end
    local content = vim.secure.read(path)
    if not content then
        return snapshot
    end
    local chunk, err = load(content, path)
    if not chunk then
        vim.notify("Diff: " .. tostring(err), vim.log.levels.WARN)
        return
    end
    _G.Diff = M
    local ok, run_err = pcall(chunk)
    _G.Diff = nil
    if not ok then
        vim.notify("Diff: " .. tostring(run_err), vim.log.levels.WARN)
    end
    return snapshot
end

local function set_tab_title(tab, title)
    if api.nvim_tabpage_is_valid(tab) then
        api.nvim_tabpage_set_var(tab, "diffexplorer_title", title)
    end
end

local function titled(base, args)
    if not args or args == "" then
        return base
    end
    return base .. " " .. args
end

local function is_diffexplorer_tab()
    local tab = api.nvim_get_current_tabpage()
    return vim.fn.gettabvar(
        api.nvim_tabpage_get_number(tab),
        "diffexplorer_title",
        ""
    ) ~= ""
end

local function mark_no_lsp(buf)
    if not buf or not api.nvim_buf_is_valid(buf) then
        return
    end
    if vim.bo[buf].buftype == "" then
        for _, client in ipairs(vim.lsp.get_clients { bufnr = buf }) do
            pcall(vim.lsp.buf_detach_client, buf, client.id)
        end
        return
    end
    vim.b[buf].diffexplorer_no_lsp = true
end

vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(ev)
        if not vim.b[ev.buf].diffexplorer_no_lsp then
            return
        end
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if client then
            pcall(vim.lsp.buf_detach_client, ev.buf, client.id)
        end
    end,
})

local function parse_spec(value)
    if
        value == "worktree"
        or value == "head"
        or value == "index"
        or value == "parent"
    then
        return value
    end
    if type(value) == "string" and value:sub(1, 2) == "@/" then
        return { path = value:sub(2) }
    end
    if type(value) == "string" and value:sub(1, 4) == "rev:" then
        return { rev = value:sub(5) }
    end
    return nil
end

function M.parse_args(args)
    local text = tostring(args or "")
    local left, path_text = text:match "^(.-)%s-%-%-%s-(.-)$"
    left = left or text
    path_text = path_text or ""
    local result = { profile = nil, before = nil, after = nil, paths = {} }
    for path in path_text:gmatch "%S+" do
        table.insert(result.paths, path)
    end
    local fallback = config.profiles[config.default_profile]
        or DEFAULT_PROFILES.working
    local has_kv = false
    for key, value in left:gmatch "(%w+)%s*=%s*(%S+)" do
        has_kv = true
        if key == "before" then
            result.before = parse_spec(value)
        elseif key == "after" then
            result.after = parse_spec(value)
        end
    end
    if has_kv then
        result.before = result.before or fallback.before
        result.after = result.after or "worktree"
        return result
    end
    local name = vim.trim(left)
    if name == "" then
        result.profile = config.default_profile
    elseif config.profiles[name] then
        result.profile = name
    elseif name:sub(1, 2) == "@/" then
        result.before = parse_spec(name)
        result.after = "worktree"
    elseif name ~= "" then
        result.before = { rev = name }
        result.after = "worktree"
    else
        result.before = fallback.before
        result.after = "worktree"
    end
    return result
end

local function named_profile(name)
    return config.profiles[name] or DEFAULT_PROFILES[name]
end

local function current_profile(parsed)
    if parsed.profile then
        return parsed.profile, named_profile(parsed.profile)
    end
    return "custom", { before = parsed.before, after = parsed.after }
end

local function cycle(state)
    local names = vim.tbl_keys(config.profiles)
    table.sort(names)
    if #names == 0 then
        return
    end
    local index = 1
    for i, name in ipairs(names) do
        if name == state.name then
            index = i
            break
        end
    end
    state.name = names[index % #names + 1]
    state.profile = named_profile(state.name)
end

local function changed_files(paths)
    local probe = vim.fn.getcwd() .. "/__diff_explorer_probe__"
    local vcs = sources.detect_vcs(probe)
    if not vcs then
        return {}
    end
    local entries = sources.status(probe, vcs)
    if not paths or #paths == 0 then
        return entries
    end
    local filtered = {}
    for _, entry in ipairs(entries) do
        local rel = sources.relative(entry.file, vcs) or entry.file
        for _, path in ipairs(paths) do
            local wanted = path:gsub("/$", "")
            if rel == wanted or rel:find(wanted .. "/", 1, true) then
                table.insert(filtered, entry)
                break
            end
        end
    end
    return filtered
end

local function current_view()
    local tab = api.nvim_get_current_tabpage()
    if views[tab] then
        return tab, views[tab]
    end
    for candidate, view in pairs(views) do
        if api.nvim_tabpage_is_valid(candidate) then
            return candidate, view
        end
    end
    return nil, nil
end

function M.open(args)
    local config_snapshot = apply_project_config()
    local parsed = M.parse_args(args)
    local name, profile = current_profile(parsed)
    local state = { name = name, profile = profile, paths = parsed.paths }
    local pane = diff.create_pane()
    local session = { tab = pane.tab, pane = pane, state = state, panel = nil }

    local function show(file)
        state.file = file
        local vcs = sources.detect_vcs(file)
        local before = vcs
                and sources.read_side(state.profile.before, file, vcs)
            or ""
        local work_buf = diff.show_file(pane, file, before)
        mark_no_lsp(work_buf)
    end

    local function build_panel()
        api.nvim_set_current_win(pane.base_win)
        session.panel = panel_module.create(
            changed_files(state.paths),
            function(file)
                pcall(show, file)
            end,
            function()
                cycle(state)
                if state.file then
                    pcall(show, state.file)
                end
            end,
            {
                listing_style = config.listing_style,
                tree_style = config.tree_style,
                width = config.panel_width,
                page_size = config.page_size,
                cwd = vim.fn.getcwd(),
                on_dir = function()
                    diff.clear(pane)
                end,
            }
        )
        mark_no_lsp(pane.base_buf)
        mark_no_lsp(session.panel.buf)
        if session.panel.entries[1] then
            pcall(show, session.panel.entries[1].file)
        end
        api.nvim_set_current_win(session.panel.win)
    end

    session.show = show
    session.build_panel = build_panel
    session.refresh_panel = function()
        if session.panel then
            session.panel.refresh(changed_files(state.paths))
            api.nvim_set_current_win(session.panel.win)
        end
    end
    build_panel()
    diff.equalize_wins(pane.base_win, pane.work_win, config.panel_width)
    set_tab_title(pane.tab, titled(config.tab_title, args))
    views[pane.tab] = session
    config = config_snapshot
    return session.panel
end

function M.file_history(args)
    local config_snapshot = apply_project_config()
    local file = vim.trim(tostring(args or ""))
    if file == "" then
        file = api.nvim_buf_get_name(api.nvim_get_current_buf())
    end
    if file == "" or vim.fn.filereadable(file) ~= 1 then
        vim.notify("Diff: file not found", vim.log.levels.WARN)
        config = config_snapshot
        return
    end
    local vcs = sources.detect_vcs(file)
    if not vcs then
        vim.notify("Diff: no repository", vim.log.levels.WARN)
        config = config_snapshot
        return
    end
    local pane = diff.create_pane()
    local session = {
        tab = pane.tab,
        pane = pane,
        state = {
            name = "working",
            profile = { before = { vcs = "head" }, after = "worktree" },
        },
        panel = nil,
    }
    local function show(entry)
        local before = entry
                and entry.rev
                and sources.at_rev(file, vcs, entry.rev)
            or ""
        diff.show_file(pane, file, before)
        mark_no_lsp(pane.base_buf)
    end
    api.nvim_set_current_win(pane.base_win)
    session.panel = panel_module.create(
        sources.history(file, vcs),
        function(_, entry)
            pcall(show, entry)
        end,
        nil,
        {
            listing_style = "list",
            tree_style = config.tree_style,
            width = config.panel_width,
            page_size = config.page_size,
            cwd = vim.fn.getcwd(),
        }
    )
    mark_no_lsp(session.panel.buf)
    if session.panel.entries[1] then
        pcall(show, session.panel.entries[1])
    end
    diff.equalize_wins(pane.base_win, pane.work_win, config.panel_width)
    set_tab_title(pane.tab, titled(config.history_tab_title, args))
    views[pane.tab] = session
    api.nvim_set_current_win(session.panel.win)
    config = config_snapshot
    return session.panel
end

function M.merge(args)
    local config_snapshot = apply_project_config()
    local cwd = vim.fn.getcwd()
    local probe = cwd .. "/__diff_explorer_probe__"
    local vcs = sources.detect_vcs(probe)
    if not vcs then
        vim.notify("Diff: no repository", vim.log.levels.WARN)
        config = config_snapshot
        return
    end
    local entries = sources.conflicts(probe, vcs)
    if #entries == 0 then
        vim.notify("Diff: no conflicts", vim.log.levels.WARN)
        config = config_snapshot
        return
    end
    local function sides_for(file)
        local ours, base, theirs = sources.conflict_sides(file, vcs)
        return { ours = ours, base = base, theirs = theirs }
    end
    local merge =
        merge_module.create(entries[1].file, sides_for(entries[1].file))
    local session = {
        tab = merge.tab,
        merge = merge,
        panel = nil,
        state = { name = "merge", profile = nil },
    }
    api.nvim_set_current_win(merge.wins[1])
    session.panel = panel_module.create(
        entries,
        function(file)
            pcall(merge_module.show, merge, file, sides_for(file))
        end,
        nil,
        {
            listing_style = "list",
            tree_style = config.tree_style,
            width = config.panel_width,
            page_size = config.page_size,
            cwd = cwd,
        }
    )
    mark_no_lsp(merge.ours_buf)
    mark_no_lsp(merge.base_buf)
    mark_no_lsp(merge.theirs_buf)
    mark_no_lsp(session.panel.buf)
    merge_module.equalize(merge, config.panel_width)
    set_tab_title(merge.tab, config.merge_tab_title)
    views[merge.tab] = session
    api.nvim_set_current_win(session.panel.win)
    config = config_snapshot
    return session.panel
end

local function two_args(args)
    local left, right = tostring(args or ""):match "^(%S+)%s+(%S+)$"
    return left, right
end

function M.diff_files(args)
    local config_snapshot = apply_project_config()
    local left, right = two_args(args)
    if not left or not right then
        vim.notify("Diff: expected two files", vim.log.levels.WARN)
        config = config_snapshot
        return
    end
    local session = compare_module.files(left, right)
    compare_module.equalize(session, 0)
    set_tab_title(session.tab, titled(config.diff_files_tab_title, args))
    views[session.tab] = {
        tab = session.tab,
        compare = session,
        state = { name = "files", profile = nil },
    }
    config = config_snapshot
    return session
end

function M.diff_dirs(args)
    local config_snapshot = apply_project_config()
    local left, right = two_args(args)
    if not left or not right then
        vim.notify("Diff: expected two directories", vim.log.levels.WARN)
        config = config_snapshot
        return
    end
    local session =
        compare_module.dirs(left, right, config.panel_width, config.page_size, {
            listing_style = config.listing_style,
            tree_style = config.tree_style,
        })
    if not session then
        config = config_snapshot
        return
    end
    compare_module.equalize(session, config.panel_width)
    set_tab_title(
        session.tab,
        titled(config.diff_dirs_tab_title, left .. " <-> " .. right)
    )
    views[session.tab] = {
        tab = session.tab,
        compare = session,
        panel = session.panel,
        state = { name = "dirs", profile = nil },
    }
    config = config_snapshot
    return session.panel
end

function M.close()
    local tab, view = current_view()
    if not view then
        return
    end
    if view.panel then
        pcall(view.panel.close)
    end
    views[tab] = nil
    if api.nvim_tabpage_is_valid(tab) then
        vim.cmd(("tabclose %d"):format(api.nvim_tabpage_get_number(tab)))
    end
end

function M.focus_files()
    local _, view = current_view()
    if view and view.panel and api.nvim_win_is_valid(view.panel.win) then
        api.nvim_set_current_win(view.panel.win)
    end
end

function M.toggle_files()
    local _, view = current_view()
    if not view then
        return
    end
    if view.panel and api.nvim_win_is_valid(view.panel.win) then
        view.panel.close()
        view.panel = nil
    elseif view.build_panel then
        view.build_panel()
    else
        vim.notify("Diff: panel cannot be reopened", vim.log.levels.WARN)
    end
end

function M.refresh()
    local _, view = current_view()
    if not view then
        return
    end
    if view.refresh_panel then
        view.refresh_panel()
    end
    if view.state.file then
        pcall(view.show, view.state.file)
    end
end

local function navigate(step)
    local _, view = current_view()
    if not view or not view.panel then
        return
    end
    local panel = view.panel
    if not api.nvim_win_is_valid(panel.win) then
        return
    end
    if step > 0 then
        panel.next_entry()
    else
        panel.prev_entry()
    end
end

function M.next()
    navigate(1)
end

function M.prev()
    navigate(-1)
end

local function page(step)
    local _, view = current_view()
    if not view or not view.panel or not view.panel.set_page then
        return
    end
    view.panel.set_page((view.panel.page or 1) + step)
end

function M.next_page()
    page(1)
end

function M.prev_page()
    page(-1)
end

function M.goto_page(target)
    local _, view = current_view()
    if not view or not view.panel or not view.panel.set_page then
        return
    end
    local number = tonumber(target)
    if not number then
        return
    end
    view.panel.set_page(number)
end

local SAFE_COMMANDS = {
    w = true,
    write = true,
    diffget = true,
    diffput = true,
    ["do"] = true,
    dp = true,
    diffupdate = true,
}

function M.redirect_cmdline(line)
    if not is_diffexplorer_tab() then
        return "<CR>"
    end
    local cmd, bang, args =
        tostring(line or ""):match "^%s*(%a+)(!?)%s*(.-)%s*$"
    if not cmd then
        return "<CR>"
    end
    if cmd:match "^Diff" or SAFE_COMMANDS[cmd] then
        return "<CR>"
    end
    local target = config.redirect_commands[cmd]
    if target then
        args = args or ""
        return "<C-u>"
            .. target
            .. bang
            .. (args == "" and "" or " " .. args)
            .. "<CR>"
    end
    vim.notify("Diff: command blocked in this tab", vim.log.levels.WARN)
    return "<C-u>"
end

M.setup()

vim.keymap.set("c", "<CR>", function()
    return M.redirect_cmdline(vim.fn.getcmdline())
end, { expr = true, noremap = true })

vim.api.nvim_create_user_command("Diff", function(opts)
    M.open(opts.args)
end, {
    nargs = "?",
    complete = function()
        return vim.tbl_keys(config.profiles)
    end,
})
vim.api.nvim_create_user_command("DiffOpen", function(opts)
    M.open(opts.args)
end, {
    nargs = "?",
    complete = function()
        return vim.tbl_keys(config.profiles)
    end,
})
vim.api.nvim_create_user_command("DiffHistory", function(opts)
    M.file_history(opts.args)
end, { nargs = "?", complete = "file" })
vim.api.nvim_create_user_command("DiffMerge", function()
    M.merge()
end, { nargs = 0, bang = true })
vim.api.nvim_create_user_command("DiffFiles", function(opts)
    M.diff_files(opts.args)
end, { nargs = "*", complete = "file" })
vim.api.nvim_create_user_command("DiffDirs", function(opts)
    M.diff_dirs(opts.args)
end, { nargs = "*", complete = "dir" })
vim.api.nvim_create_user_command("DiffToggle", function()
    M.toggle_files()
end, { nargs = 0, bang = true })
vim.api.nvim_create_user_command("DiffClose", function()
    M.close()
end, { nargs = 0, bang = true })
vim.api.nvim_create_user_command("DiffFocusFiles", function()
    M.focus_files()
end, { nargs = 0, bang = true })
vim.api.nvim_create_user_command("DiffToggleFiles", function()
    M.toggle_files()
end, { nargs = 0, bang = true })
vim.api.nvim_create_user_command("DiffRefresh", function()
    M.refresh()
end, { nargs = 0, bang = true })
vim.api.nvim_create_user_command("DiffNext", function()
    M.next()
end, { nargs = 0 })
vim.api.nvim_create_user_command("DiffPrev", function()
    M.prev()
end, { nargs = 0 })
vim.api.nvim_create_user_command("DiffNextPage", function()
    M.next_page()
end, { nargs = 0 })
vim.api.nvim_create_user_command("DiffPrevPage", function()
    M.prev_page()
end, { nargs = 0 })
vim.api.nvim_create_user_command("DiffGotoPage", function(opts)
    M.goto_page(opts.args)
end, { nargs = 1 })

vim.keymap.set("n", "<leader>vd", function()
    M.open ""
end, { desc = "Diff Explorer" })

return M
