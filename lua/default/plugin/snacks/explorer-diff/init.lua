local sources = require "default.plugin.snacks.explorer-diff.sources"
local diff = require "default.plugin.snacks.explorer-diff.diff"
local preview = require "snacks.picker.preview"

local M = {}

local DEFAULT_PROFILES = {
    working = { before = { vcs = "head" }, after = "worktree" },
    staged = { before = { vcs = "head" }, after = { vcs = "index" } },
    unstaged = { before = { vcs = "index" }, after = "worktree" },
}

local config = {
    default_profile = "working",
    profiles = {},
}

local cache = {}

function M.setup(opts)
    opts = opts or {}
    config.default_profile = opts.default_profile or config.default_profile
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

local function render(ctx, state)
    local item = ctx.item
    local text
    if not item.file or item.dir then
        text = "No diff for this entry"
    else
        local vcs = sources.detect_vcs(item.file)
        if not vcs then
            text = "No version control repository"
        else
            local key = item.file
                .. "|"
                .. state.name
                .. "|"
                .. vim.fn.getftime(item.file)
            text = cache[key]
            if not text then
                local before =
                    sources.read_side(state.profile.before, item.file, vcs)
                local after =
                    sources.read_side(state.profile.after, item.file, vcs)
                text = diff.unified(before, after, "before", "after")
                if vim.tbl_count(cache) > 200 then
                    cache = {}
                end
                cache[key] = text
            end
        end
    end
    item.preview = { text = text, ft = "diff", loc = false }
    return preview.preview(ctx)
end

local function cycle(picker, state)
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
    picker:show_preview()
end

function M.open(args)
    local parsed = M.parse_args(args)
    local name, profile = current_profile(parsed)
    local state = { name = name, profile = profile }

    return require("snacks").picker.explorer {
        title = "Diff Explorer",
        layout = "custom",
        focus = "list",
        preview = function(ctx)
            return render(ctx, state)
        end,
        actions = {
            diff_profile_next = {
                action = function(picker)
                    cycle(picker, state)
                end,
            },
            diff_open_vimdiff = {
                action = function(picker)
                    local item = picker:current()
                    if not item or not item.file or item.dir then
                        return
                    end
                    local vcs = sources.detect_vcs(item.file)
                    if not vcs then
                        return
                    end
                    local before =
                        sources.read_side(state.profile.before, item.file, vcs)
                    local after =
                        sources.read_side(state.profile.after, item.file, vcs)
                    diff.open_vimdiff(before, after)
                end,
            },
        },
        win = {
            list = {
                keys = {
                    ["<Tab>"] = "diff_profile_next",
                    ["<C-v>"] = "diff_open_vimdiff",
                },
            },
        },
    }
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
