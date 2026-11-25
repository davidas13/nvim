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

print "DIFF EXPLORER TEST OK"
