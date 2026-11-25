local api = vim.api
local sources = require "default.plugin.snacks.explorer-diff.sources"
local diff = require "default.plugin.snacks.explorer-diff.diff"
local panel_module = require "default.plugin.snacks.explorer-diff.panel"
local merge_module = require "default.plugin.snacks.explorer-diff.merge"

local M = {}

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
    listing_style = "list",
    panel_width = 40,
    tab_title = "DiffExplorer",
    history_tab_title = "DiffExplorerHistory",
    merge_tab_title = "DiffExplorerMerge",
    redirect_commands = {},
}

local views = {}

function M.setup(opts)
    opts = opts or {}
    config.default_profile = opts.default_profile or config.default_profile
    config.listing_style = opts.listing_style or config.listing_style
    config.panel_width = opts.panel_width or config.panel_width
    config.tab_title = opts.tab_title or config.tab_title
    config.history_tab_title = opts.history_tab_title
        or config.history_tab_title
    config.merge_tab_title = opts.merge_tab_title or config.merge_tab_title
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
        vim.notify("DiffExplorer: " .. tostring(err), vim.log.levels.WARN)
        return
    end
    _G.DiffExplorer = M
    local ok, run_err = pcall(chunk)
    _G.DiffExplorer = nil
    if not ok then
        vim.notify("DiffExplorer: " .. tostring(run_err), vim.log.levels.WARN)
    end
    return snapshot
end

local function set_tab_title(tab, title)
    if api.nvim_tabpage_is_valid(tab) then
        api.nvim_tabpage_set_var(tab, "diffexplorer_title", title)
    end
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
    return nil
end

function M.parse_args(args)
    local result = { profile = nil, before = nil, after = nil }
    local fallback = config.profiles[config.default_profile]
        or DEFAULT_PROFILES.working
    local has_kv = false
    for key, value in tostring(args or ""):gmatch "(%w+)%s*=%s*(%S+)" do
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
    local name = vim.trim(tostring(args or ""))
    if name == "" then
        result.profile = config.default_profile
    elseif config.profiles[name] then
        result.profile = name
    else
        result.before = parse_spec(name) or fallback.before
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

local function changed_files()
    local probe = vim.fn.getcwd() .. "/__diff_explorer_probe__"
    local vcs = sources.detect_vcs(probe)
    if not vcs then
        return {}
    end
    return sources.status(probe, vcs)
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
    local state = { name = name, profile = profile }
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
        session.panel = panel_module.create(changed_files(), function(file)
            pcall(show, file)
        end, function()
            cycle(state)
            if state.file then
                pcall(show, state.file)
            end
        end, {
            listing_style = config.listing_style,
            width = config.panel_width,
            cwd = vim.fn.getcwd(),
        })
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
            session.panel.refresh(changed_files())
            api.nvim_set_current_win(session.panel.win)
        end
    end
    build_panel()
    diff.equalize_wins(pane.base_win, pane.work_win, config.panel_width)
    set_tab_title(pane.tab, config.tab_title)
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
        vim.notify("DiffExplorer: file not found", vim.log.levels.WARN)
        config = config_snapshot
        return
    end
    local vcs = sources.detect_vcs(file)
    if not vcs then
        vim.notify("DiffExplorer: no repository", vim.log.levels.WARN)
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
            width = config.panel_width,
            cwd = vim.fn.getcwd(),
        }
    )
    mark_no_lsp(session.panel.buf)
    if session.panel.entries[1] then
        pcall(show, session.panel.entries[1])
    end
    diff.equalize_wins(pane.base_win, pane.work_win, config.panel_width)
    set_tab_title(pane.tab, config.history_tab_title)
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
        vim.notify("DiffExplorer: no repository", vim.log.levels.WARN)
        config = config_snapshot
        return
    end
    local entries = sources.conflicts(probe, vcs)
    if #entries == 0 then
        vim.notify("DiffExplorer: no conflicts", vim.log.levels.WARN)
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
            width = config.panel_width,
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
        vim.notify(
            "DiffExplorer: panel cannot be reopened",
            vim.log.levels.WARN
        )
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
    local count = #panel.view_items
    if count == 0 then
        return
    end
    local row = api.nvim_win_get_cursor(panel.win)[1]
    local index = row
    for _ = 1, count do
        index = index + step
        if index < 1 then
            index = count
        elseif index > count then
            index = 1
        end
        if panel.view_items[index].kind == "file" then
            panel.select_index(index)
            return
        end
    end
end

function M.next()
    navigate(1)
end

function M.prev()
    navigate(-1)
end

function M.redirect_cmdline(line)
    if not is_diffexplorer_tab() then
        return "<CR>"
    end
    local cmd, bang, args =
        tostring(line or ""):match "^%s*(%a+)(!?)%s*(.-)%s*$"
    local target = cmd and config.redirect_commands[cmd]
    if not target then
        return "<CR>"
    end
    args = args or ""
    return "<C-u>"
        .. target
        .. bang
        .. (args == "" and "" or " " .. args)
        .. "<CR>"
end

M.setup()

vim.keymap.set("c", "<CR>", function()
    return M.redirect_cmdline(vim.fn.getcmdline())
end, { expr = true, noremap = true })

vim.api.nvim_create_user_command("DiffExplorer", function(opts)
    M.open(opts.args)
end, {
    nargs = "?",
    complete = function()
        return vim.tbl_keys(config.profiles)
    end,
})
vim.api.nvim_create_user_command("DiffExplorerOpen", function(opts)
    M.open(opts.args)
end, {
    nargs = "?",
    complete = function()
        return vim.tbl_keys(config.profiles)
    end,
})
vim.api.nvim_create_user_command("DiffExplorerFileHistory", function(opts)
    M.file_history(opts.args)
end, { nargs = "?", complete = "file" })
vim.api.nvim_create_user_command("DiffExplorerMerge", function()
    M.merge()
end, { nargs = 0, bang = true })
vim.api.nvim_create_user_command("DiffExplorerClose", function()
    M.close()
end, { nargs = 0, bang = true })
vim.api.nvim_create_user_command("DiffExplorerFocusFiles", function()
    M.focus_files()
end, { nargs = 0, bang = true })
vim.api.nvim_create_user_command("DiffExplorerToggleFiles", function()
    M.toggle_files()
end, { nargs = 0, bang = true })
vim.api.nvim_create_user_command("DiffExplorerRefresh", function()
    M.refresh()
end, { nargs = 0, bang = true })
vim.api.nvim_create_user_command("DiffExplorerNext", function()
    M.next()
end, { nargs = 0 })
vim.api.nvim_create_user_command("DiffExplorerPrev", function()
    M.prev()
end, { nargs = 0 })

vim.keymap.set("n", "<leader>vd", function()
    M.open ""
end, { desc = "Diff Explorer" })

return M
