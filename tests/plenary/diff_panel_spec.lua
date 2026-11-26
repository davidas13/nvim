local diff = require "default.plugin.diff"

describe("diff panel", function()
    local left
    local right
    local panel
    local original_cwd

    local function write(path, text)
        local handle = assert(io.open(path, "w"))
        handle:write(text)
        handle:close()
    end

    local function open_tree(page_size)
        diff.setup {
            listing_style = "tree",
            tree_style = "unicode",
            tree_indent = { branch = 2, vertical = 3 },
            page_size = page_size,
        }
        vim.cmd.cd(left)
        panel = diff.diff_dirs(left .. " " .. right)
    end

    local function visible_lines()
        return vim.api.nvim_buf_get_lines(panel.buf, 0, -1, false)
    end

    local function tooltip_window()
        for _, candidate in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_get_config(candidate).relative ~= "" then
                return candidate
            end
        end
        return nil
    end

    before_each(function()
        original_cwd = vim.fn.getcwd()
        left = vim.fn.tempname()
        right = vim.fn.tempname()
        vim.fn.mkdir(left .. "/alpha/beta", "p")
        vim.fn.mkdir(right .. "/alpha/beta", "p")
        for index = 1, 4 do
            write(left .. "/alpha/beta/f" .. index .. ".txt", "left\n")
            write(right .. "/alpha/beta/f" .. index .. ".txt", "right\n")
        end
        write(left .. "/z.txt", "left\n")
        write(right .. "/z.txt", "right\n")
    end)

    after_each(function()
        if panel then
            pcall(diff.close)
            panel = nil
        end
        vim.cmd.cd(original_cwd)
        vim.fn.delete(left, "rf")
        vim.fn.delete(right, "rf")
    end)

    it(
        "should pin the folder chain when a tree page starts inside a folder",
        function()
            open_tree(3)
            vim.cmd "DiffGotoPage 2"
            local lines = visible_lines()
            assert.are.equal("├── alpha/", lines[1], "outer folder line")
            assert.are.equal(
                "│   └── beta/",
                lines[2],
                "inner folder line"
            )
        end
    )

    it(
        "should start the cursor on the first entry when a header is pinned",
        function()
            open_tree(3)
            vim.cmd "DiffGotoPage 2"
            assert.are.equal(
                3,
                vim.api.nvim_win_get_cursor(panel.win)[1],
                "cursor row below two header lines"
            )
        end
    )

    it(
        "should omit the header when a tree page starts at the top level",
        function()
            open_tree(3)
            vim.cmd "DiffGotoPage 3"
            local lines = visible_lines()
            assert.are.equal(
                "└── M  z.txt",
                lines[1],
                "top level entry line"
            )
        end
    )

    it("should omit the header when listing style is list", function()
        diff.setup { listing_style = "list", page_size = 3 }
        vim.cmd.cd(left)
        panel = diff.diff_dirs(left .. " " .. right)
        vim.cmd "DiffGotoPage 2"
        local lines = visible_lines()
        assert.is_false(
            lines[1] == "├── alpha/",
            "list mode has no folder header"
        )
        assert.is_true(
            lines[1]:find("alpha/beta/", 1, true) ~= nil,
            "list mode shows a file path"
        )
    end)

    it("should show the focused folder path when K is pressed", function()
        open_tree(3)
        vim.cmd.normal "K"
        local tip = tooltip_window()
        assert.is_not_nil(tip, "floating tooltip window")
        assert.are.equal(
            "alpha",
            vim.api.nvim_buf_get_lines(
                vim.api.nvim_win_get_buf(tip),
                0,
                -1,
                false
            )[1],
            "focused folder relative path"
        )
        vim.api.nvim_exec_autocmds("CursorMoved", { buffer = panel.buf })
    end)

    it("should advance one page when N is pressed", function()
        open_tree(3)
        vim.cmd.normal "N"
        assert.is_true(
            vim.wo[panel.win].winbar:find("Page 2/3", 1, true) ~= nil,
            "winbar page after next-page key"
        )
    end)

    it("should return one page when P is pressed", function()
        open_tree(3)
        vim.cmd "DiffGotoPage 2"
        vim.cmd.normal "P"
        assert.is_true(
            vim.wo[panel.win].winbar:find("Page 1/3", 1, true) ~= nil,
            "winbar page after previous-page key"
        )
    end)

    it("should move to the next file when n is pressed", function()
        open_tree(3)
        vim.cmd.normal "n"
        local row = vim.api.nvim_win_get_cursor(panel.win)[1]
        assert.are.equal(
            "│       ├── M  f1.txt",
            visible_lines()[row],
            "line under the cursor after next-file key"
        )
    end)

    it("should move to the previous file when p is pressed", function()
        open_tree(3)
        vim.cmd "DiffGotoPage 2"
        vim.cmd.normal "p"
        local row = vim.api.nvim_win_get_cursor(panel.win)[1]
        assert.are.equal(
            "│       ├── M  f1.txt",
            visible_lines()[row],
            "line under the cursor after previous-file key"
        )
    end)
end)
