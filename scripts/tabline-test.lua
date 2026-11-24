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
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_win_set_buf(win, buf)
        vim.api.nvim_buf_set_name(
            buf,
            ("/tmp/tabline-test-%d/%s"):format(scenario, entry[1])
        )
        vim.wo[win].diff = entry[2] or false
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
end)

if not ok then
    print("TABLINE TEST FAIL " .. tostring(err))
    vim.cmd "cquit 1"
end
print "tabline test passed"
