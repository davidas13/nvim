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

function M.open(args)
    local parsed = M.parse_args(args)
    local name, profile = current_profile(parsed)
    local state = { name = name, profile = profile }
    local pane = diff.create_pane()

    local function changed_files()
        local probe = vim.fn.getcwd() .. "/__diff_explorer_probe__"
        local vcs = sources.detect_vcs(probe)
        if not vcs then
            return {}
        end
        return sources.status(probe, vcs)
    end

    local function show(file)
        state.file = file
        local vcs = sources.detect_vcs(file)
        local before = vcs
                and sources.read_side(state.profile.before, file, vcs)
            or ""
        diff.show_file(pane, file, before)
    end

    local function refresh()
        if state.file then
            show(state.file)
        end
    end

    local function cycle_profile()
        cycle(state)
        pcall(refresh)
    end

    vim.api.nvim_set_current_win(pane.base_win)
    local file_panel = panel_module.create(
        changed_files(),
        function(file)
            pcall(show, file)
        end,
        cycle_profile,
        {
            listing_style = config.listing_style,
            cwd = vim.fn.getcwd(),
        }
    )
    if file_panel.entries[1] then
        show(file_panel.entries[1].file)
    end
    vim.api.nvim_set_current_win(file_panel.win)
    return file_panel
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

vim.keymap.set("n", "<leader>vd", function()
    M.open ""
end, { desc = "Diff Explorer" })

return M
