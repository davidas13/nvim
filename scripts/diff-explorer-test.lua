local sources = require "default.plugin.snacks.explorer-diff.sources"
local diff = require "default.plugin.snacks.explorer-diff.diff"
local panel_module = require "default.plugin.snacks.explorer-diff.panel"
local explorer_diff = require "default.plugin.snacks.explorer-diff"

local function run(cmd, cwd)
    return vim.system({ "sh", "-c", cmd }, { cwd = cwd, text = true }):wait()
end

local function write(path, text)
    local handle = assert(io.open(path, "w"))
    handle:write(text)
    handle:close()
end

local function eq(actual, expected, label)
    assert(
        actual == expected,
        label
            .. ": expected ["
            .. tostring(expected)
            .. "] got ["
            .. tostring(actual)
            .. "]"
    )
end

local base = vim.fn.tempname()
vim.fn.mkdir(base, "p")

local git_dir = base .. "/git"
vim.fn.mkdir(git_dir .. "/sub", "p")
write(git_dir .. "/file.txt", "original\n")
write(git_dir .. "/sub/nested.txt", "nested\n")
run(
    "git init -q && git config user.email t@example.com && git config user.name t && git add . && git commit -qm init",
    git_dir
)
write(git_dir .. "/file.txt", "changed\n")
write(git_dir .. "/untracked.txt", "new file\n")

local hg_dir = base .. "/hg"
vim.fn.mkdir(hg_dir, "p")
write(hg_dir .. "/file.txt", "hg original\n")
run("hg init && hg add file.txt && hg commit -u t -m init", hg_dir)
write(hg_dir .. "/file.txt", "hg changed\n")

local jj_dir = base .. "/jj"
vim.fn.mkdir(jj_dir, "p")
write(jj_dir .. "/file.txt", "jj original\n")
run("jj init --git && jj describe -m init && jj new -m next", jj_dir)
write(jj_dir .. "/file.txt", "jj changed\n")

local both = base .. "/both"
vim.fn.mkdir(both .. "/.git", "p")
vim.fn.mkdir(both .. "/.jj", "p")
write(both .. "/file.txt", "x\n")

local prod = base .. "/prod"
vim.fn.mkdir(prod .. "/sub", "p")
write(prod .. "/sub/nested.txt", "prod nested\n")

eq(sources.detect_vcs(git_dir .. "/file.txt"), "git", "detect git")
eq(sources.detect_vcs(hg_dir .. "/file.txt"), "hg", "detect hg")
eq(sources.detect_vcs(jj_dir .. "/file.txt"), "jj", "detect jj")
eq(sources.detect_vcs(both .. "/file.txt"), "jj", "detect colocated")
eq(sources.detect_vcs(base .. "/loose.txt"), nil, "detect outside repo")
eq(
    sources.relative(git_dir .. "/sub/nested.txt", "git"),
    "sub/nested.txt",
    "relative path"
)

eq(
    sources.read_side({ vcs = "head" }, git_dir .. "/file.txt", "git"),
    "original\n",
    "git head"
)
eq(
    sources.read_side("worktree", git_dir .. "/file.txt", "git"),
    "changed\n",
    "git worktree"
)
eq(
    sources.read_side({ vcs = "index" }, git_dir .. "/file.txt", "git"),
    "original\n",
    "git index"
)
eq(
    sources.read_side({ vcs = "head" }, git_dir .. "/untracked.txt", "git"),
    "",
    "git untracked"
)
eq(
    sources.read_side({ vcs = "head" }, hg_dir .. "/file.txt", "hg"),
    "hg original\n",
    "hg head"
)
eq(
    sources.read_side({ vcs = "head" }, jj_dir .. "/file.txt", "jj"),
    "jj original\n",
    "jj parent"
)
eq(
    sources.read_side({ path = prod }, git_dir .. "/sub/nested.txt", "git"),
    "prod nested\n",
    "external path mapping"
)

local function has_file(entries, path)
    for _, entry in ipairs(entries) do
        if vim.endswith(entry.file, path) then
            return true
        end
    end
    return false
end

local git_status = sources.status(git_dir .. "/file.txt", "git")
assert(has_file(git_status, "/file.txt"), "git status: modified file")
assert(has_file(git_status, "/untracked.txt"), "git status: untracked file")
local hg_status = sources.status(hg_dir .. "/file.txt", "hg")
assert(has_file(hg_status, "/file.txt"), "hg status: modified file")
local jj_status = sources.status(jj_dir .. "/file.txt", "jj")
assert(has_file(jj_status, "/file.txt"), "jj status: modified file")

local parsed = explorer_diff.parse_args "staged"
eq(parsed.profile, "staged", "parse named profile")
parsed = explorer_diff.parse_args "before=head after=worktree"
eq(parsed.before, "head", "parse before")
eq(parsed.after, "worktree", "parse after")
parsed = explorer_diff.parse_args "@/tmp/prod"
eq(type(parsed.before), "table", "parse external before")
eq(parsed.before.path, "/tmp/prod", "parse external path")

local pane = diff.create_pane()
assert(vim.api.nvim_tabpage_is_valid(pane.tab), "create pane: invalid tabpage")
assert(
    vim.api.nvim_win_get_option(pane.work_win, "diff"),
    "create pane: work diff"
)
assert(
    vim.api.nvim_win_get_option(pane.base_win, "diff"),
    "create pane: base diff"
)
eq(vim.bo[pane.base_buf].modifiable, false, "create pane: base not modifiable")
eq(vim.bo[pane.base_buf].readonly, true, "create pane: base readonly")
assert(
    vim.api.nvim_win_get_position(pane.base_win)[2]
        < vim.api.nvim_win_get_position(pane.work_win)[2],
    "create pane: base left of work"
)

local work_buf = diff.show_file(pane, git_dir .. "/file.txt", "original\n")
assert(
    work_buf and vim.api.nvim_buf_is_valid(work_buf),
    "show file: invalid buffer"
)
assert(
    vim.endswith(vim.api.nvim_buf_get_name(work_buf), "/file.txt"),
    "show file: name"
)
eq(vim.bo[work_buf].buftype, "", "show file: file-backed")
eq(vim.bo[work_buf].bufhidden, "hide", "show file: hidden buffer")
assert(
    vim.api.nvim_win_get_option(pane.work_win, "diff"),
    "show file: work diff"
)
assert(
    vim.api.nvim_win_get_option(pane.work_win, "scrollbind"),
    "show file: scrollbind"
)
eq(
    table.concat(vim.api.nvim_buf_get_lines(pane.base_buf, 0, -1, false), "\n"),
    "original\n",
    "show file: base lines"
)
eq(
    vim.bo[pane.base_buf].modifiable,
    false,
    "show file: base stays not modifiable"
)

diff.show_file(pane, git_dir .. "/sub/nested.txt", "")
assert(
    vim.api.nvim_win_get_option(pane.work_win, "diff"),
    "switch file: work diff reapplied"
)
assert(
    vim.api.nvim_win_get_option(pane.base_win, "diff"),
    "switch file: base diff reapplied"
)

for i = 1, 10 do
    local path = base .. "/switch" .. i .. ".txt"
    write(path, "content " .. i .. "\n")
    local ok, err = pcall(diff.show_file, pane, path, "base\n")
    assert(ok, "switch loop " .. i .. ": " .. tostring(err))
    assert(
        vim.api.nvim_win_get_option(pane.work_win, "diff"),
        "switch loop " .. i .. ": work diff"
    )
end

vim.api.nvim_set_current_win(pane.base_win)
local selected
local panel = panel_module.create({
    { file = git_dir .. "/file.txt", status = "M" },
    { file = git_dir .. "/sub/nested.txt", status = "?" },
}, function(file)
    selected = file
end, function() end)
assert(vim.api.nvim_win_is_valid(panel.win), "panel: valid window")
eq(vim.bo[panel.buf].readonly, true, "panel: readonly")
eq(vim.bo[panel.buf].modifiable, false, "panel: not modifiable")
eq(vim.api.nvim_win_get_option(panel.win, "diff"), false, "panel: not in diff")
assert(
    vim.api.nvim_win_get_position(panel.win)[2]
        < vim.api.nvim_win_get_position(pane.base_win)[2],
    "panel: left of base"
)
vim.api.nvim_set_current_win(panel.win)
vim.api.nvim_win_set_cursor(panel.win, { 2, 0 })
vim.cmd.doautocmd "CursorMoved"
eq(selected, git_dir .. "/sub/nested.txt", "panel: cursor selects file")
local has_tab_key = false
for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(panel.buf, "n")) do
    if mapping.lhs == "<Tab>" then
        has_tab_key = true
    end
end
assert(has_tab_key, "panel: profile key mapped")
panel.refresh {}
eq(
    table.concat(vim.api.nvim_buf_get_lines(panel.buf, 0, -1, false), "\n"),
    "No changed files",
    "panel: empty state"
)
panel.close()

vim.api.nvim_set_current_win(pane.base_win)
local tree = panel_module.create({
    { file = git_dir .. "/file.txt", status = "M" },
    { file = git_dir .. "/sub/nested.txt", status = "?" },
}, function() end, nil, { listing_style = "tree", cwd = git_dir })
local dir_row
for i, item in ipairs(tree.view_items) do
    if item.kind == "dir" then
        dir_row = i
        break
    end
end
assert(dir_row, "tree: folder node")
local tree_count = #tree.view_items
vim.api.nvim_set_current_win(tree.win)
vim.api.nvim_win_set_cursor(tree.win, { dir_row, 0 })
for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(tree.buf, "n")) do
    if mapping.lhs == "<CR>" or mapping.lhs == "\r" then
        mapping.callback()
    end
end
assert(#tree.view_items < tree_count, "tree: folder collapses")
tree.close()

print "DIFF EXPLORER TEST OK"
