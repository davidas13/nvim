local api = vim.api
local sources = require "default.plugin.snacks.explorer-diff.sources"
local diff = require "default.plugin.snacks.explorer-diff.diff"
local panel_module = require "default.plugin.snacks.explorer-diff.panel"

local M = {}

local DEFAULT_PROFILES = {
    working = { before = { vcs = "head" }, after = "worktree" },
    staged = { before = { vcs = "head" }, after = { vcs = "index" } },
    unstaged = { before = { vcs = "index" }, after = "worktree" },
}

local config = {
    default_profile = "working",
    profiles = {},
    listing_style = "list",
}

local views = {}

function M.setup(opts)
    opts = opts or {}
    config.default_profile = opts.default_profile or config.default_profile
    config.listing_style = opts.listing_style or config.listing_style
    config.profiles =
        vim.tbl_deep_extend("force", DEFAULT_PROFILES, opts.profiles or {})
end

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
        diff.show_file(pane, file, before)
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
            cwd = vim.fn.getcwd(),
        })
        if session.panel.entries[1] then
            pcall(show, session.panel.entries[1].file)
        end
        api.nvim_set_current_win(session.panel.win)
    end

    session.show = show
    session.build_panel = build_panel
    build_panel()
    views[pane.tab] = session
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
    else
        view.build_panel()
    end
end

function M.refresh()
    local _, view = current_view()
    if not view then
        return
    end
    if view.panel then
        view.panel.refresh(changed_files())
        api.nvim_set_current_win(view.panel.win)
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

M.setup()

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
