local sources = require "default.plugin.diff.sources"

describe("diff sources", function()
    local root

    before_each(function()
        root = vim.fn.tempname()
        vim.fn.mkdir(root .. "/sub", "p")
    end)

    after_each(function()
        vim.fn.delete(root, "rf")
    end)

    it("should return the root when a marker exists in an ancestor", function()
        vim.fn.mkdir(root .. "/.git")
        local file = root .. "/sub/file.lua"
        assert.are.equal(
            root,
            sources.root(file, "git"),
            "root for a nested file in " .. root
        )
    end)

    it("should return the nearest root when markers are nested", function()
        vim.fn.mkdir(root .. "/.git")
        vim.fn.mkdir(root .. "/sub/.git")
        local file = root .. "/sub/file.lua"
        assert.are.equal(
            root .. "/sub",
            sources.root(file, "git"),
            "nearest root for a nested repository in " .. root
        )
    end)

    it("should return nil when no repository marker exists", function()
        local file = root .. "/sub/file.lua"
        assert.is_nil(sources.root(file, "git"), "root outside a repository")
    end)

    it("should detect the VCS from a marker in an ancestor", function()
        vim.fn.mkdir(root .. "/.hg")
        local file = root .. "/sub/file.lua"
        assert.are.equal(
            "hg",
            sources.detect_vcs(file),
            "VCS for a nested file in " .. root
        )
    end)

    it("should detect the nearest VCS when markers differ", function()
        vim.fn.mkdir(root .. "/.git")
        vim.fn.mkdir(root .. "/sub/.jj")
        local file = root .. "/sub/file.lua"
        assert.are.equal(
            "jj",
            sources.detect_vcs(file),
            "nearest VCS for a nested repository in " .. root
        )
    end)

    it("should return nil VCS when no marker exists", function()
        local file = root .. "/sub/file.lua"
        assert.is_nil(sources.detect_vcs(file), "VCS outside a repository")
    end)

    it("should return the path relative to the repository root", function()
        vim.fn.mkdir(root .. "/.git")
        local file = root .. "/sub/file.lua"
        assert.are.equal(
            "sub/file.lua",
            sources.relative(file, "git"),
            "relative path for a nested file in " .. root
        )
    end)

    it("should return nil relative path when no marker exists", function()
        local file = root .. "/sub/file.lua"
        assert.is_nil(
            sources.relative(file, "git"),
            "relative path outside a repository"
        )
    end)
end)
