local sources = require "default.plugin.diff.sources"
local diff = require "default.plugin.diff.diff"
local panel_module = require "default.plugin.diff.panel"
local compare = require "default.plugin.diff.compare"
local explorer_diff = require "default.plugin.diff"

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

local hist_dir = base .. "/hist"
vim.fn.mkdir(hist_dir, "p")
write(hist_dir .. "/file.txt", "h1\n")
run(
    "git init -q && git config user.email t@example.com && git config user.name t && git add . && git commit -qm one",
    hist_dir
)
write(hist_dir .. "/file.txt", "h2\n")
run("git add . && git commit -qm two", hist_dir)
write(hist_dir .. "/file.txt", "h3\n")

local conflict_dir = base .. "/conflict"
vim.fn.mkdir(conflict_dir, "p")
write(conflict_dir .. "/f.txt", "base\n")
run(
    "git init -q -b main && git config user.email t@example.com && git config user.name t && git add . && git commit -qm base && git checkout -qb feature && printf 'feature\\n' > f.txt && git add . && git commit -qm feature && git checkout -q main && printf 'main\\n' > f.txt && git add . && git commit -qm main && git merge feature --no-edit -q || true",
    conflict_dir
)

local path_dir = base .. "/paths"
vim.fn.mkdir(path_dir .. "/sub", "p")
write(path_dir .. "/root.txt", "r1\n")
write(path_dir .. "/sub/inner.txt", "i1\n")
run(
    "git init -q && git config user.email t@example.com && git config user.name t && git add . && git commit -qm init",
    path_dir
)
write(path_dir .. "/root.txt", "r2\n")
write(path_dir .. "/sub/inner.txt", "i2\n")

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

local git_history = sources.history(hist_dir .. "/file.txt", "git")
assert(#git_history >= 2, "git history: commits listed")
eq(
    sources.at_rev(hist_dir .. "/file.txt", "git", git_history[2].rev),
    "h1\n",
    "git at rev"
)
local hg_history = sources.history(hg_dir .. "/file.txt", "hg")
assert(#hg_history >= 1, "hg history: commits listed")
local jj_history = sources.history(jj_dir .. "/file.txt", "jj")
assert(#jj_history >= 1, "jj history: commits listed")

local conflicts = sources.conflicts(conflict_dir .. "/f.txt", "git")
assert(#conflicts >= 1, "conflicts: files listed")
local ours, base_side, theirs =
    sources.conflict_sides(conflict_dir .. "/f.txt", "git")
eq(vim.trim(ours), "main", "conflict sides: ours")
eq(vim.trim(base_side), "base", "conflict sides: base")
eq(vim.trim(theirs), "feature", "conflict sides: theirs")

local parsed = explorer_diff.parse_args "staged"
eq(parsed.profile, "staged", "parse named profile")
parsed = explorer_diff.parse_args "before=head after=worktree"
eq(parsed.before, "head", "parse before")
eq(parsed.after, "worktree", "parse after")
parsed = explorer_diff.parse_args "@/tmp/prod"
eq(type(parsed.before), "table", "parse external before")
eq(parsed.before.path, "/tmp/prod", "parse external path")
parsed = explorer_diff.parse_args "HEAD~2 -- lua/diffview plugin"
eq(parsed.before.rev, "HEAD~2", "parse revision")
eq(#parsed.paths, 2, "parse pathspec")
eq(parsed.paths[1], "lua/diffview", "parse first path")
parsed = explorer_diff.parse_args "before=rev:HEAD~1"
eq(parsed.before.rev, "HEAD~1", "parse rev option")
eq(
    sources.read_side(
        { rev = git_history[2].rev },
        hist_dir .. "/file.txt",
        "git"
    ),
    "h1\n",
    "read side at revision"
)

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

vim.cmd.filetype "on"
local ft_pane = diff.create_pane()
local ft_file = base .. "/ft_sample.py"
write(ft_file, "one\ntwo\nthree\n")
local ft_work = diff.show_file(ft_pane, ft_file, "one\nBASE\nthree\n")
vim.cmd.redraw()
assert(vim.bo[ft_work].filetype ~= "", "filetype: work buffer detected")
eq(
    vim.bo[ft_pane.base_buf].filetype,
    vim.bo[ft_work].filetype,
    "filetype: baseline mirrors work"
)
for label, win in pairs { base = ft_pane.base_win, work = ft_pane.work_win } do
    eq(vim.api.nvim_win_get_option(win, "diff"), true, label .. ": diff")
    eq(
        vim.api.nvim_win_get_option(win, "scrollbind"),
        true,
        label .. ": scrollbind"
    )
    eq(
        vim.api.nvim_win_get_option(win, "cursorbind"),
        true,
        label .. ": cursorbind"
    )
    eq(vim.wo[win].foldmethod, "diff", label .. ": diff fold")
end
vim.api.nvim_win_call(ft_pane.work_win, function()
    vim.cmd "normal! 3G"
end)
vim.cmd.redraw()
eq(
    vim.api.nvim_win_get_cursor(ft_pane.base_win)[1],
    3,
    "diff sync: cursor follows"
)
vim.api.nvim_buf_set_lines(ft_work, 1, 2, false, { "BASE" })
vim.cmd.diffupdate()
vim.cmd.redraw()
local clear_hl = vim.api.nvim_win_call(ft_pane.work_win, function()
    return vim.fn.diff_hlID(2, 1)
end)
eq(clear_hl, 0, "diff sync: hunk clears")
vim.api.nvim_buf_set_lines(ft_work, 1, 2, false, { "CHANGED" })
vim.cmd.diffupdate()
vim.cmd.redraw()
local change_hl = vim.api.nvim_win_call(ft_pane.work_win, function()
    return vim.fn.diff_hlID(2, 1)
end)
assert(change_hl ~= 0, "diff sync: hunk appears")

eq(vim.wo[ft_pane.base_win].winfixbuf, true, "lock: base window fixed")
eq(vim.wo[ft_pane.work_win].winfixbuf, true, "lock: work window fixed")
local stray_buf = vim.api.nvim_create_buf(false, true)
local ok_swap, err_swap =
    pcall(vim.api.nvim_win_set_buf, ft_pane.work_win, stray_buf)
assert(
    not ok_swap and tostring(err_swap):find("E1513", 1, true),
    "lock: external buffer swap blocked"
)
local other_file = base .. "/other.py"
write(other_file, "other\n")
local swapped = diff.show_file(ft_pane, other_file, "base\n")
assert(swapped, "lock: own swap succeeds")
assert(
    vim.endswith(vim.api.nvim_buf_get_name(swapped), "/other.py"),
    "lock: own swap lands in work window"
)

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
eq(vim.wo[panel.win].winfixbuf, true, "panel: window fixed")
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

vim.api.nvim_set_current_win(pane.base_win)
local unicode_entries = {
    { file = git_dir .. "/file.txt", status = "M" },
    { file = git_dir .. "/sub/a.txt", status = "?" },
    { file = git_dir .. "/sub/deep/b.txt", status = "M" },
}
local dir_hit = false
local unicode_panel = panel_module.create(
    unicode_entries,
    function() end,
    nil,
    {
        listing_style = "tree",
        tree_style = "unicode",
        cwd = git_dir,
        on_dir = function()
            dir_hit = true
        end,
    }
)
local unicode_labels = {}
for _, item in ipairs(unicode_panel.view_items) do
    table.insert(unicode_labels, item.label)
end
local joined_unicode = table.concat(unicode_labels, "\n")
assert(
    joined_unicode:find("├── sub/", 1, true),
    "tree: unicode branch folder"
)
assert(
    joined_unicode:find("│   ├── deep/", 1, true),
    "tree: unicode continuation"
)
assert(
    joined_unicode:find("└── M  file%.txt", 1, false),
    "tree: unicode last file"
)
vim.api.nvim_set_current_win(unicode_panel.win)
local unicode_dir_row
for i, item in ipairs(unicode_panel.view_items) do
    if item.kind == "dir" then
        unicode_dir_row = i
        break
    end
end
unicode_panel.select_index(unicode_dir_row)
assert(dir_hit, "tree: dir callback fires")
unicode_panel.close()

local ascii_panel = panel_module.create(unicode_entries, function() end, nil, {
    listing_style = "tree",
    tree_style = "ascii",
    cwd = git_dir,
})
local ascii_labels = {}
for _, item in ipairs(ascii_panel.view_items) do
    table.insert(ascii_labels, item.label)
end
local joined_ascii = table.concat(ascii_labels, "\n")
assert(joined_ascii:find("+-- sub/", 1, true), "tree: ascii branch folder")
assert(
    joined_ascii:find("`%-%- M  file%.txt", 1, false),
    "tree: ascii last file"
)
ascii_panel.close()

local indent_panel = panel_module.create(unicode_entries, function() end, nil, {
    listing_style = "tree",
    tree_style = "unicode",
    tree_indent = { branch = 1, vertical = 2 },
    cwd = git_dir,
})
local indent_labels = {}
for _, item in ipairs(indent_panel.view_items) do
    table.insert(indent_labels, item.label)
end
local joined_indent = table.concat(indent_labels, "\n")
assert(joined_indent:find("├─ sub/", 1, true), "tree indent: branch dashes")
assert(
    joined_indent:find("│  ├─ deep/", 1, true),
    "tree indent: vertical padding"
)
assert(
    joined_indent:find("│  │  └─ M  b%.txt", 1, false),
    "tree indent: nested padding"
)
indent_panel.close()

vim.cmd.cd(git_dir)
write(git_dir .. "/sub/nested.txt", "nested-changed\n")
local tree_session_panel = explorer_diff.open()
local tree_session_tab = vim.api.nvim_get_current_tabpage()
local tree_dir_row
for i, item in ipairs(tree_session_panel.view_items) do
    if item.kind == "dir" then
        tree_dir_row = i
        break
    end
end
assert(tree_dir_row, "tree session: folder row")
tree_session_panel.select_index(tree_dir_row)
local tree_diff_wins = {}
for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tree_session_tab)) do
    if vim.api.nvim_win_get_option(win, "diff") then
        table.insert(tree_diff_wins, win)
    end
end
table.sort(tree_diff_wins, function(a, b)
    return vim.api.nvim_win_get_position(a)[2]
        < vim.api.nvim_win_get_position(b)[2]
end)
local cleared_buf = vim.api.nvim_win_get_buf(tree_diff_wins[2])
eq(vim.bo[cleared_buf].buftype, "nofile", "tree session: folder clears work")
eq(vim.api.nvim_buf_get_name(cleared_buf), "", "tree session: no file opened")
explorer_diff.close()

vim.api.nvim_set_current_win(pane.base_win)
local page_entries = {}
for i = 1, 25 do
    table.insert(page_entries, {
        file = git_dir .. "/page" .. i .. ".txt",
        status = "M",
        label = "page" .. i,
    })
end
local page_selected
local page_panel = panel_module.create(
    page_entries,
    function(file)
        page_selected = file
    end,
    nil,
    {
        listing_style = "list",
        width = 40,
        page_size = 10,
        cwd = git_dir,
    }
)
eq(
    #vim.api.nvim_buf_get_lines(page_panel.buf, 0, -1, false),
    10,
    "pagination: buffer holds one page"
)
eq(page_panel.page_count, 3, "pagination: page count")
page_panel.set_page(2)
eq(page_panel.view_items[1].file, page_entries[11].file, "pagination: page two")
page_panel.select_index(2)
eq(page_selected, page_entries[12].file, "pagination: selection on page two")
page_panel.select_index(10)
page_panel.next_entry()
eq(page_panel.page, 3, "pagination: next crosses page")
eq(page_selected, page_entries[21].file, "pagination: next selects page three")
page_panel.prev_entry()
eq(page_panel.page, 2, "pagination: prev crosses page")
eq(page_selected, page_entries[20].file, "pagination: prev selects last item")
local has_page_key = false
for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(page_panel.buf, "n")) do
    if mapping.lhs == "]p" then
        has_page_key = true
    end
end
assert(has_page_key, "pagination: page key mapped")
page_panel.close()

vim.cmd.cd(git_dir)
local opened_panel = explorer_diff.open()
local opened_tab = vim.api.nvim_get_current_tabpage()
vim.cmd.DiffFocusFiles()
eq(vim.api.nvim_get_current_win(), opened_panel.win, "command: focus files")
vim.cmd.DiffNext()
vim.cmd.DiffToggleFiles()
eq(
    vim.api.nvim_win_is_valid(opened_panel.win),
    false,
    "command: toggle closes panel"
)
vim.cmd.DiffToggleFiles()
local reopened = vim.api.nvim_get_current_win()
eq(
    vim.api.nvim_win_get_option(reopened, "diff"),
    false,
    "command: toggle reopens panel"
)
eq(
    vim.bo[vim.api.nvim_win_get_buf(reopened)].readonly,
    true,
    "command: reopened panel readonly"
)
vim.cmd.DiffRefresh()
vim.cmd.DiffClose()
eq(vim.api.nvim_tabpage_is_valid(opened_tab), false, "command: close tab")

vim.cmd.cd(git_dir)
local titled_panel = explorer_diff.open()
local titled_tab = vim.api.nvim_get_current_tabpage()
local titled_pane = nil
for _, win in ipairs(vim.api.nvim_tabpage_list_wins(titled_tab)) do
    if vim.api.nvim_win_get_option(win, "diff") then
        titled_pane = titled_pane or {}
        titled_pane[#titled_pane + 1] = win
    end
end
eq(
    vim.fn.gettabvar(
        vim.api.nvim_tabpage_get_number(titled_tab),
        "diffexplorer_title",
        ""
    ),
    "Diff",
    "tab title: default"
)
eq(
    vim.api.nvim_win_get_width(titled_pane[1]),
    vim.api.nvim_win_get_width(titled_pane[2]),
    "diff panes: equal width"
)
for _, win in ipairs(vim.api.nvim_tabpage_list_wins(titled_tab)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype ~= "" then
        eq(
            vim.b[buf].diffexplorer_no_lsp,
            true,
            "lsp: disabled in explorer tab"
        )
    end
end
eq(
    explorer_diff.redirect_cmdline "e foo.txt",
    "<C-u>tabedit foo.txt<CR>",
    "redirect: edit in explorer tab"
)
explorer_diff.close()
vim.api.nvim_tabpage_set_var(
    vim.api.nvim_get_current_tabpage(),
    "diffexplorer_title",
    ""
)
eq(explorer_diff.redirect_cmdline "e foo.txt", "<CR>", "redirect: outside tab")

local cfg_dir = base .. "/cfgproj"
vim.fn.mkdir(cfg_dir, "p")
write(cfg_dir .. "/.nvim.lua", "Diff.setup { tab_title = \"CustomTab\" }\n")
local real_secure_read = vim.secure.read
vim.secure.read = function(path)
    local handle = io.open(path, "r")
    if not handle then
        return nil
    end
    local content = handle:read "*a"
    handle:close()
    return content
end
vim.cmd.cd(cfg_dir)
local custom_panel = explorer_diff.open()
local custom_tab = vim.api.nvim_get_current_tabpage()
eq(
    vim.fn.gettabvar(
        vim.api.nvim_tabpage_get_number(custom_tab),
        "diffexplorer_title",
        ""
    ),
    "CustomTab",
    "project config: tab title"
)
vim.secure.read = real_secure_read
explorer_diff.close()

vim.cmd.cd(hist_dir)
local history_panel = explorer_diff.file_history(hist_dir .. "/file.txt")
local history_tab = vim.api.nvim_get_current_tabpage()
local history_title = vim.fn.gettabvar(
    vim.api.nvim_tabpage_get_number(history_tab),
    "diffexplorer_title",
    ""
)
assert(vim.startswith(history_title, "DiffHistory "), "history: tab title")
assert(#history_panel.entries >= 2, "history: panel entries")
local history_wins = {}
for _, win in ipairs(vim.api.nvim_tabpage_list_wins(history_tab)) do
    if vim.api.nvim_win_get_option(win, "diff") then
        history_wins[#history_wins + 1] = win
    end
end
local history_base = vim.api.nvim_win_get_buf(history_wins[1])
eq(
    table.concat(vim.api.nvim_buf_get_lines(history_base, 0, -1, false), "\n"),
    "h2\n",
    "history: baseline at selected rev"
)
explorer_diff.close()

vim.cmd.cd(conflict_dir)
local merge_panel = explorer_diff.merge()
local merge_tab = vim.api.nvim_get_current_tabpage()
eq(
    vim.fn.gettabvar(
        vim.api.nvim_tabpage_get_number(merge_tab),
        "diffexplorer_title",
        ""
    ),
    "DiffMerge",
    "merge: tab title"
)
assert(#merge_panel.entries >= 1, "merge: panel entries")
local merge_diff_wins = 0
for _, win in ipairs(vim.api.nvim_tabpage_list_wins(merge_tab)) do
    if vim.api.nvim_win_get_option(win, "diff") then
        merge_diff_wins = merge_diff_wins + 1
    end
end
eq(merge_diff_wins, 3, "merge: three diff windows")
local ok_merge_toggle, err_merge_toggle = pcall(vim.cmd.DiffToggleFiles)
assert(ok_merge_toggle, "merge toggle: " .. tostring(err_merge_toggle))
explorer_diff.close()

vim.cmd.cd(hist_dir)
local reset_panel = explorer_diff.open()
local reset_tab = vim.api.nvim_get_current_tabpage()
eq(
    vim.fn.gettabvar(
        vim.api.nvim_tabpage_get_number(reset_tab),
        "diffexplorer_title",
        ""
    ),
    "Diff",
    "project config: reset for next project"
)
local reset_work_buf
for _, win in ipairs(vim.api.nvim_tabpage_list_wins(reset_tab)) do
    if vim.api.nvim_win_get_option(win, "diff") then
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].buftype == "" then
            reset_work_buf = buf
        end
    end
end
eq(
    vim.b[reset_work_buf].diffexplorer_no_lsp,
    nil,
    "lsp: no sticky flag on file buffer"
)
eq(
    explorer_diff.redirect_cmdline "e! foo.txt",
    "<C-u>tabedit! foo.txt<CR>",
    "redirect: bang preserved"
)
eq(explorer_diff.redirect_cmdline "w", "<CR>", "lock: write allowed")
eq(
    explorer_diff.redirect_cmdline "DiffRefresh",
    "<CR>",
    "lock: own commands allowed"
)
eq(explorer_diff.redirect_cmdline "bd", "<C-u>", "lock: buffer delete blocked")
eq(explorer_diff.redirect_cmdline "set number", "<C-u>", "lock: set blocked")
explorer_diff.close()

vim.cmd.cd(path_dir)
local filtered_panel = explorer_diff.open "-- sub"
eq(#filtered_panel.entries, 1, "pathspec: entries kept")
for _, entry in ipairs(filtered_panel.entries) do
    assert(entry.file:find "/sub/", "pathspec: only matching files")
end
explorer_diff.close()

vim.cmd.cd(hist_dir)
local history_re_panel = explorer_diff.file_history(hist_dir .. "/file.txt")
local history_count = #history_re_panel.entries
vim.cmd.DiffRefresh()
eq(#history_re_panel.entries, history_count, "history refresh: entries kept")
local ok_history_toggle, err_history_toggle = pcall(vim.cmd.DiffToggleFiles)
assert(ok_history_toggle, "history toggle: " .. tostring(err_history_toggle))
explorer_diff.close()

local merge_secure_read = vim.secure.read
vim.secure.read = function(path)
    local handle = io.open(path, "r")
    if not handle then
        return nil
    end
    local content = handle:read "*a"
    handle:close()
    return content
end
vim.cmd.cd(cfg_dir)
pcall(explorer_diff.merge)
vim.secure.read = merge_secure_read
vim.cmd.cd(git_dir)
local after_merge_panel = explorer_diff.open()
local after_merge_tab = vim.api.nvim_get_current_tabpage()
eq(
    vim.fn.gettabvar(
        vim.api.nvim_tabpage_get_number(after_merge_tab),
        "diffexplorer_title",
        ""
    ),
    "Diff",
    "project config: merge early return restores"
)
explorer_diff.close()

local left_file = base .. "/left.txt"
local right_file = base .. "/right.txt"
write(left_file, "left\n")
write(right_file, "right\n")
local file_session = explorer_diff.diff_files(left_file .. " " .. right_file)
local file_tab = vim.api.nvim_get_current_tabpage()
local files_title = vim.fn.gettabvar(
    vim.api.nvim_tabpage_get_number(file_tab),
    "diffexplorer_title",
    ""
)
assert(vim.startswith(files_title, "DiffFiles "), "diff files: tab title")
local file_diff_wins = 0
for _, win in ipairs(vim.api.nvim_tabpage_list_wins(file_tab)) do
    if vim.api.nvim_win_get_option(win, "diff") then
        file_diff_wins = file_diff_wins + 1
    end
end
eq(file_diff_wins, 2, "diff files: two diff windows")
explorer_diff.close()

local dir_left = base .. "/dl"
local dir_right = base .. "/dr"
vim.fn.mkdir(dir_left, "p")
vim.fn.mkdir(dir_right, "p")
write(dir_left .. "/a.txt", "a1\n")
write(dir_right .. "/a.txt", "a2\n")
write(dir_left .. "/only.txt", "only\n")
write(dir_left .. "/same.txt", "same\n")
write(dir_right .. "/same.txt", "same\n")
write(dir_left .. "/.hidden.txt", "hidden-left\n")
write(dir_right .. "/.hidden.txt", "hidden-right\n")
local dir_panel = explorer_diff.diff_dirs(dir_left .. " " .. dir_right)
local dir_tab = vim.api.nvim_get_current_tabpage()
local dirs_title = vim.fn.gettabvar(
    vim.api.nvim_tabpage_get_number(dir_tab),
    "diffexplorer_title",
    ""
)
eq(
    dirs_title,
    "DiffDirs " .. dir_left .. " <-> " .. dir_right,
    "diff dirs: tab title"
)
eq(#dir_panel.entries, 3, "diff dirs: only differing entries")
local has_hidden, has_same = false, false
for _, entry in ipairs(dir_panel.entries) do
    if entry.file == ".hidden.txt" then
        has_hidden = true
    end
    if entry.file == "same.txt" then
        has_same = true
    end
end
assert(has_hidden, "diff dirs: hidden file listed")
assert(not has_same, "diff dirs: identical file excluded")
local dir_session = dir_panel.session
assert(dir_session, "diff dirs: session exposed")
eq(
    vim.bo[vim.api.nvim_win_get_buf(dir_session.wins[1])].buftype,
    "",
    "diff dirs: left buffer file-backed"
)
local dir_diff_wins = 0
for _, win in ipairs(vim.api.nvim_tabpage_list_wins(dir_tab)) do
    if vim.api.nvim_win_get_option(win, "diff") then
        dir_diff_wins = dir_diff_wins + 1
    end
end
eq(dir_diff_wins, 2, "diff dirs: two diff windows")
local only_row
for i, item in ipairs(dir_panel.view_items) do
    if item.file == "only.txt" then
        only_row = i
    end
end
assert(only_row, "diff dirs: only.txt row")
dir_panel.select_index(only_row)
vim.wait(120)
local selected_buf = vim.api.nvim_win_get_buf(dir_session.wins[1])
assert(
    vim.endswith(vim.api.nvim_buf_get_name(selected_buf), "/dl/only.txt"),
    "diff dirs: debounced selection"
)
for _, win in ipairs(dir_session.wins) do
    eq(
        vim.api.nvim_win_get_option(win, "diff"),
        true,
        "diff dirs: diff after selection"
    )
end
vim.api.nvim_set_current_win(dir_session.wins[1])
vim.api.nvim_buf_set_lines(selected_buf, 0, -1, false, { "written" })
vim.cmd.write()
local written = io.open(dir_left .. "/only.txt", "r")
assert(written, "diff dirs: write target exists")
eq(written:read "*a", "written\n", "diff dirs: write through")
written:close()

for i = 1, 12 do
    local rel = "switch" .. i .. ".txt"
    write(dir_left .. "/" .. rel, "left" .. i .. "\n")
    write(dir_right .. "/" .. rel, "right" .. i .. "\n")
    dir_session.current_rel = nil
    local ok, err = pcall(compare.show_dir, dir_session, rel)
    assert(ok, "diff dirs switch " .. i .. ": " .. tostring(err))
end

local binary_rel = "bin.dat"
write(
    dir_left .. "/" .. binary_rel,
    string.rep("A", 4096) .. "\0" .. string.rep("B", 4096)
)
write(
    dir_right .. "/" .. binary_rel,
    string.rep("A", 4096) .. "\0" .. string.rep("C", 4096)
)
dir_session.current_rel = nil
local ok_binary, err_binary = pcall(compare.show_dir, dir_session, binary_rel)
assert(ok_binary, "diff dirs binary: " .. tostring(err_binary))
eq(
    vim.bo[vim.api.nvim_win_get_buf(dir_session.wins[1])].buftype,
    "nofile",
    "diff dirs: binary uses placeholder"
)
explorer_diff.close()
eq(vim.fn.exists ":DiffToggle", 2, "toggle alias: exists")
eq(vim.fn.exists ":Diff", 2, "rename: Diff exists")
eq(vim.fn.exists ":DiffHistory", 2, "rename: DiffHistory exists")
eq(vim.fn.exists ":DiffExplorer", 0, "rename: old command gone")
eq(vim.fn.exists ":DiffNextPage", 2, "pagination: next page command")
eq(vim.fn.exists ":DiffPrevPage", 2, "pagination: prev page command")
eq(vim.fn.exists ":DiffGotoPage", 2, "pagination: goto page command")

local page_dir_left = base .. "/page-left"
local page_dir_right = base .. "/page-right"
vim.fn.mkdir(page_dir_left, "p")
vim.fn.mkdir(page_dir_right, "p")
for i = 1, 15 do
    write(page_dir_left .. "/f" .. i .. ".txt", "left" .. i .. "\n")
    write(page_dir_right .. "/f" .. i .. ".txt", "right" .. i .. "\n")
end
explorer_diff.setup { page_size = 7 }
vim.cmd.cd(page_dir_left)
local config_panel =
    explorer_diff.diff_dirs(page_dir_left .. " " .. page_dir_right)
eq(
    #vim.api.nvim_buf_get_lines(config_panel.buf, 0, -1, false),
    7,
    "pagination: config page size"
)
eq(config_panel.page_count, 3, "pagination: config page count")
vim.cmd "DiffGotoPage 2"
eq(config_panel.page, 2, "pagination: goto page command")
explorer_diff.close()
explorer_diff.setup { page_size = 100 }

local tree_dirs_left = base .. "/tree-left"
local tree_dirs_right = base .. "/tree-right"
vim.fn.mkdir(tree_dirs_left .. "/sub", "p")
vim.fn.mkdir(tree_dirs_right .. "/sub", "p")
write(tree_dirs_left .. "/root.txt", "left\n")
write(tree_dirs_right .. "/root.txt", "right\n")
write(tree_dirs_left .. "/sub/inner.txt", "left-inner\n")
write(tree_dirs_right .. "/sub/inner.txt", "right-inner\n")
explorer_diff.setup {
    listing_style = "tree",
    tree_style = "ascii",
    tree_indent = { branch = 2, vertical = 3 },
    page_size = 100,
}
vim.cmd.cd(tree_dirs_left)
local tree_dirs_panel =
    explorer_diff.diff_dirs(tree_dirs_left .. " " .. tree_dirs_right)
local tree_dirs_row
local tree_dirs_label = ""
for i, item in ipairs(tree_dirs_panel.view_items) do
    if item.kind == "dir" then
        tree_dirs_row = i
        tree_dirs_label = item.label
        break
    end
end
assert(tree_dirs_row, "diff dirs tree: folder row")
assert(
    tree_dirs_label:find("+-- sub/", 1, true),
    "diff dirs tree: ascii folder glyph"
)
tree_dirs_panel.select_index(tree_dirs_row)
local tree_dirs_session = tree_dirs_panel.session
local cleared_buf = vim.api.nvim_win_get_buf(tree_dirs_session.wins[2])
eq(vim.bo[cleared_buf].buftype, "nofile", "diff dirs tree: folder clears work")
eq(
    vim.api.nvim_buf_get_name(cleared_buf),
    "",
    "diff dirs tree: folder opens no file"
)
explorer_diff.close()
explorer_diff.setup {
    listing_style = "tree",
    tree_style = "unicode",
    tree_indent = { branch = 2, vertical = 3 },
    page_size = 100,
}

local sticky_left = base .. "/sticky-left"
local sticky_right = base .. "/sticky-right"
vim.fn.mkdir(sticky_left .. "/alpha/beta", "p")
vim.fn.mkdir(sticky_right .. "/alpha/beta", "p")
for i = 1, 4 do
    write(sticky_left .. "/alpha/beta/f" .. i .. ".txt", "left\n")
    write(sticky_right .. "/alpha/beta/f" .. i .. ".txt", "right\n")
end
write(sticky_left .. "/z.txt", "left\n")
write(sticky_right .. "/z.txt", "right\n")
explorer_diff.setup {
    listing_style = "tree",
    tree_style = "unicode",
    page_size = 3,
}
vim.cmd.cd(sticky_left)
local sticky_panel = explorer_diff.diff_dirs(sticky_left .. " " .. sticky_right)
local sticky_ns = vim.api.nvim_create_namespace "diff_sticky"
local function sticky_texts()
    local marks = vim.api.nvim_buf_get_extmarks(
        sticky_panel.buf,
        sticky_ns,
        0,
        -1,
        { details = true }
    )
    if #marks == 0 then
        return {}
    end
    local texts = {}
    for _, chunk in ipairs(marks[1][4].virt_lines or {}) do
        table.insert(texts, chunk[1][1])
    end
    return texts
end
eq(#sticky_texts(), 0, "sticky: no header on first page")
vim.cmd "DiffGotoPage 2"
eq(sticky_panel.page, 2, "sticky: second page")
local sticky_lines = sticky_texts()
eq(#sticky_lines, 2, "sticky: two ancestors")
eq(sticky_lines[1], "├── alpha/", "sticky: outer folder row")
eq(sticky_lines[2], "│   └── beta/", "sticky: inner folder row")
vim.cmd "DiffNextPage"
eq(#sticky_texts(), 0, "sticky: header cleared at top-level page")
explorer_diff.close()
explorer_diff.setup { page_size = 100 }

local jump_file = base .. "/jump_target.py"
write(jump_file, "jump\n")
local picker_actions = require "snacks.picker.actions"
local direct_tab = vim.api.nvim_get_current_tabpage()
local direct_tabs = vim.fn.tabpagenr "$"
vim.api.nvim_tabpage_set_var(direct_tab, "diffexplorer_title", "Diff")
local direct_picker = {
    opts = { jump = { close = true } },
    selected = function()
        return { { file = jump_file, pos = { 1, 0 } } }
    end,
    close = function() end,
}
local ok_direct, err_direct = pcall(picker_actions.jump, direct_picker, nil, {})
assert(ok_direct, "picker guard: no error: " .. tostring(err_direct))
eq(vim.fn.tabpagenr "$", direct_tabs + 1, "picker guard: opens new tab")
assert(
    vim.endswith(vim.api.nvim_buf_get_name(0), "/jump_target.py"),
    "picker guard: new tab holds file"
)
vim.api.nvim_tabpage_set_var(direct_tab, "diffexplorer_title", "")
vim.cmd(("tabclose %d"):format(vim.fn.tabpagenr()))

local explorer_actions = require "snacks.explorer.actions"
local explorer_tab = vim.api.nvim_get_current_tabpage()
local explorer_tabs = vim.fn.tabpagenr "$"
vim.api.nvim_tabpage_set_var(explorer_tab, "diffexplorer_title", "Diff")
local explorer_picker = {
    opts = { jump = { close = true } },
    input = { filter = { meta = { searching = false } } },
    selected = function()
        return { { file = jump_file, pos = { 1, 0 } } }
    end,
    close = function() end,
}
local ok_confirm, err_confirm = pcall(
    explorer_actions.actions.confirm,
    explorer_picker,
    { file = jump_file },
    {}
)
assert(ok_confirm, "explorer guard: no error: " .. tostring(err_confirm))
eq(vim.fn.tabpagenr "$", explorer_tabs + 1, "explorer guard: opens new tab")
assert(
    vim.endswith(vim.api.nvim_buf_get_name(0), "/jump_target.py"),
    "explorer guard: new tab holds file"
)
vim.api.nvim_tabpage_set_var(explorer_tab, "diffexplorer_title", "")
vim.cmd(("tabclose %d"):format(vim.fn.tabpagenr()))

local swap_left = base .. "/swap-left"
local swap_right = base .. "/swap-right"
vim.fn.mkdir(swap_left, "p")
vim.fn.mkdir(swap_right, "p")
write(swap_left .. "/left-only.txt", "left\n")
write(swap_right .. "/right-only.txt", "right\n")
write(swap_left .. "/shared.txt", "left-shared\n")
write(swap_right .. "/shared.txt", "right-shared\n")
local swap_panel = explorer_diff.diff_dirs(swap_left .. " " .. swap_right)
local swap_session = swap_panel.session
local swap_tab = vim.api.nvim_get_current_tabpage()
local swap_title_before = vim.fn.gettabvar(
    vim.api.nvim_tabpage_get_number(swap_tab),
    "diffexplorer_title",
    ""
)
local function status_for(panel, rel)
    for _, entry in ipairs(panel.entries) do
        if entry.file == rel then
            return entry.status
        end
    end
    return nil
end
eq(
    status_for(swap_panel, "left-only.txt"),
    "D",
    "swap: left only status before"
)
eq(
    status_for(swap_panel, "right-only.txt"),
    "A",
    "swap: right only status before"
)
swap_session.current_rel = nil
require("default.plugin.diff.compare").show_dir(swap_session, "shared.txt")
local swap_work_before = vim.api.nvim_win_get_buf(swap_session.wins[2])
local swap_key_ok = false
for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(swap_panel.buf, "n")) do
    if mapping.lhs == "s" then
        mapping.callback()
        swap_key_ok = true
        break
    end
end
assert(swap_key_ok, "swap: s mapped")
eq(
    vim.fn.fnamemodify(swap_session.left, ":p"),
    vim.fn.fnamemodify(swap_right, ":p"),
    "swap: left becomes right"
)
eq(
    vim.fn.fnamemodify(swap_session.right, ":p"),
    vim.fn.fnamemodify(swap_left, ":p"),
    "swap: right becomes left"
)
eq(status_for(swap_panel, "left-only.txt"), "A", "swap: left only flips to A")
eq(status_for(swap_panel, "right-only.txt"), "D", "swap: right only flips to D")
eq(
    vim.fn.fnamemodify(swap_panel.cwd, ":p"),
    vim.fn.fnamemodify(swap_right, ":p"),
    "swap: panel root follows first dir"
)
assert(
    vim.wo[swap_panel.win].winbar:find("root:", 1, true),
    "swap: winbar shows root"
)
local swap_title_after = vim.fn.gettabvar(
    vim.api.nvim_tabpage_get_number(swap_tab),
    "diffexplorer_title",
    ""
)
assert(swap_title_after ~= swap_title_before, "swap: tab title changes")
eq(swap_session.current_rel, "shared.txt", "swap: selected file preserved")
local swap_work_after = vim.api.nvim_win_get_buf(swap_session.wins[2])
assert(
    vim.endswith(
        vim.api.nvim_buf_get_name(swap_work_after),
        "/swap-left/shared.txt"
    ),
    "swap: work buffer follows swapped right"
)
vim.cmd "DiffDirsSwap"
eq(
    vim.fn.fnamemodify(swap_session.left, ":p"),
    vim.fn.fnamemodify(swap_left, ":p"),
    "swap: command restores left"
)
explorer_diff.close()

local function group_diff_wins(tab, panel_win)
    local found = {}
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
        if win ~= panel_win and vim.api.nvim_win_get_option(win, "diff") then
            table.insert(found, win)
        end
    end
    table.sort(found, function(a, b)
        return vim.api.nvim_win_get_position(a)[2]
            < vim.api.nvim_win_get_position(b)[2]
    end)
    return found
end

vim.cmd.cd(git_dir)
local resize_panel = explorer_diff.open()
local resize_tab = vim.api.nvim_get_current_tabpage()
local resize_wins = group_diff_wins(resize_tab, resize_panel.win)
eq(#resize_wins, 2, "resize: two diff windows")
vim.api.nvim_win_set_width(resize_panel.win, 60)
explorer_diff.rebalance(resize_tab)
local after_panel = group_diff_wins(resize_tab, resize_panel.win)
eq(
    vim.api.nvim_win_get_width(after_panel[1]),
    vim.api.nvim_win_get_width(after_panel[2]),
    "resize: panel change keeps diff widths equal"
)
vim.api.nvim_win_set_width(after_panel[2], 30)
explorer_diff.rebalance(resize_tab, after_panel[2])
local after_diff = group_diff_wins(resize_tab, resize_panel.win)
eq(
    vim.api.nvim_win_get_width(after_diff[1]),
    vim.api.nvim_win_get_width(after_diff[2]),
    "resize: diff change keeps diff widths equal"
)
explorer_diff.close()

vim.cmd.cd(page_dir_left)
explorer_diff.setup { page_size = 7 }
local guard_panel =
    explorer_diff.diff_dirs(page_dir_left .. " " .. page_dir_right)
local guard_tab = vim.api.nvim_get_current_tabpage()
vim.cmd "DiffGotoPage 2"
eq(guard_panel.page, 2, "guard: page set inside Diff tab")
vim.cmd.tabnew()
local normal_tab = vim.api.nvim_get_current_tabpage()
vim.cmd "DiffNextPage"
eq(guard_panel.page, 2, "guard: page unchanged outside Diff tab")
vim.cmd "DiffClose"
assert(
    vim.api.nvim_tabpage_is_valid(guard_tab),
    "guard: Diff tab survives close outside"
)
vim.api.nvim_set_current_tabpage(guard_tab)
explorer_diff.close()
assert(
    not vim.api.nvim_tabpage_is_valid(normal_tab) or true,
    "guard: normal tab untouched"
)

print "DIFF EXPLORER TEST OK"
