-- Assert-based check for tab labels produced by the custom tabline.

local scenario = 0

local function label(spec)
    scenario = scenario + 1
    if vim.fn.winnr "$" > 1 then
        vim.cmd "only!"
    end
    for i, entry in ipairs(spec) do
        if i > 1 then
            vim.cmd "below new"
        end
        local win = vim.api.nvim_get_current_win()
        local buf = vim.api.nvim_create_buf(false, false)
        vim.api.nvim_win_set_buf(win, buf)
        vim.api.nvim_buf_set_name(
            buf,
            ("/tmp/tabline-test-%d/%s"):format(scenario, entry[1])
        )
        vim.wo[win].diff = entry[2] or false
        if entry[3] then
            vim.bo[buf].buftype = entry[3]
        end
    end
    return _G.tabline_without_close()
end

local function expect(spec, name, case)
    local actual = label(spec)
    local expected = ("%%#TabLineSel#%%1T 1 %s %%#TabLineFill#%%T"):format(name)
    assert(
        actual == expected,
        ("tabline for %s: expected %q, got %q"):format(case, expected, actual)
    )
end

local function expect_plugin_windows()
    if vim.fn.winnr "$" > 1 then
        vim.cmd "only!"
    end
    scenario = scenario + 1
    local base = vim.api.nvim_create_buf(false, false)
    vim.api.nvim_win_set_buf(vim.api.nvim_get_current_win(), base)
    vim.api.nvim_buf_set_name(
        base,
        ("/tmp/tabline-test-%d/base.lua"):format(scenario)
    )

    vim.cmd "below new"
    local side_win = vim.api.nvim_get_current_win()
    vim.bo[vim.api.nvim_win_get_buf(side_win)].buftype = "nofile"

    local float_opts = {
        relative = "editor",
        width = 20,
        height = 5,
        row = 1,
        col = 1,
    }
    for _, buftype in ipairs { "prompt", "nofile" } do
        local buf = vim.api.nvim_create_buf(false, true)
        vim.bo[buf].buftype = buftype
        vim.api.nvim_open_win(buf, false, float_opts)
    end

    local actual = _G.tabline_without_close()
    local expected = "%#TabLineSel#%1T 1 base.lua %#TabLineFill#%T"
    assert(
        actual == expected,
        ("tabline for plugin windows: expected %q, got %q"):format(
            expected,
            actual
        )
    )
end

local function expect_stale_tab()
    if vim.fn.winnr "$" > 1 then
        vim.cmd "only!"
    end
    local real_tabpagenr = vim.fn.tabpagenr
    vim.fn.tabpagenr = function(arg)
        if arg == "$" then
            return real_tabpagenr "$" + 1
        end
        return real_tabpagenr()
    end
    local rendered, render_err = pcall(_G.tabline_without_close)
    vim.fn.tabpagenr = real_tabpagenr
    assert(
        rendered,
        "tabline for stale tabpage: expected no error, got "
            .. tostring(render_err)
    )
end

local ok, err = pcall(function()
    expect({ { "file1", false } }, "file1", "one window")
    expect(
        { { "file1", false }, { "file2", false } },
        "file1, file2",
        "plain windows"
    )
    expect(
        { { "file1", true }, { "file2", true } },
        "file1 <-> file2",
        "diff windows"
    )
    expect(
        { { "file1", false }, { "file2", true }, { "file3", true } },
        "file1, file2 <-> file3",
        "mixed windows"
    )
    expect(
        { { "file1", true }, { "snapshot", true, "nowrite" } },
        "file1 <-> snapshot",
        "diff snapshot buffer"
    )
    expect_plugin_windows()
    expect_stale_tab()
end)

if not ok then
    print("TABLINE TEST FAIL " .. tostring(err))
    vim.cmd "cquit 1"
end
print "tabline test passed"
