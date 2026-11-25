local M = {}

local MARKS = { ".jj", ".git", ".hg" }

local function normalize(path)
    return vim.fs.normalize(path)
end

local function output(cmd, cwd)
    local result = vim.system(cmd, { cwd = cwd, text = true }):wait()
    return result.stdout or "", result.code
end

local function read_file(path)
    local handle = io.open(path, "rb")
    if not handle then
        return ""
    end
    local content = handle:read "*a"
    handle:close()
    return content or ""
end

function M.root(file, vcs)
    local dir = vim.fs.dirname(normalize(file))
    local marker = "." .. vcs
    while dir do
        if vim.fn.isdirectory(dir .. "/" .. marker) == 1 then
            return dir
        end
        local parent = vim.fs.dirname(dir)
        if parent == dir then
            return nil
        end
        dir = parent
    end
end

function M.detect_vcs(file)
    local dir = vim.fs.dirname(normalize(file))
    while dir do
        for _, mark in ipairs(MARKS) do
            if vim.fn.isdirectory(dir .. "/" .. mark) == 1 then
                return mark:sub(2)
            end
        end
        local parent = vim.fs.dirname(dir)
        if parent == dir then
            return nil
        end
        dir = parent
    end
end

function M.relative(file, vcs)
    local root = M.root(file, vcs)
    if not root then
        return nil
    end
    return vim.fs.relpath(root, normalize(file))
end

local function vcs_text(revision, file, vcs, rel, root)
    if vcs == "git" then
        local ref = revision == "index" and ":" .. rel or "HEAD:" .. rel
        local text = output({ "git", "show", ref }, root)
        return text
    end
    if vcs == "hg" then
        local text = output({ "hg", "cat", "-r", ".", rel }, root)
        return text
    end
    local text, code = output({ "jj", "cat", "-r", "@-", rel }, root)
    if code ~= 0 then
        text = output({ "jj", "file", "show", "-r", "@-", rel }, root)
    end
    return text
end

function M.read_side(spec, file, vcs)
    if type(spec) == "function" then
        return spec(file, vcs)
    end
    if spec == "worktree" then
        return read_file(file)
    end
    local rel = M.relative(file, vcs)
    if not rel then
        return ""
    end
    if type(spec) == "table" and spec.path then
        return read_file(normalize(spec.path .. "/" .. rel))
    end
    local root = M.root(file, vcs)
    if not root then
        return ""
    end
    local revision = type(spec) == "table" and spec.vcs or spec
    if vcs ~= "git" and revision == "index" then
        revision = "head"
    end
    return vcs_text(revision, file, vcs, rel, root)
end

local function parse_status(vcs, text, root)
    local entries = {}
    for line in vim.gsplit(text, "\n", { plain = true }) do
        if line ~= "" then
            local code, path
            if vcs == "git" then
                code = line:sub(1, 2)
                path = line:sub(4)
                if path:find(" -> ", 1, true) then
                    path = vim.split(path, " -> ", { plain = true })[2]
                end
            elseif vcs == "hg" then
                code = line:sub(1, 1)
                path = line:sub(3)
            else
                code, path = line:match "^([MARD?C]) (.+)$"
            end
            if code and path then
                code = vim.trim(code):sub(1, 1)
                path = vim.trim(path)
                if path ~= "" then
                    table.insert(entries, {
                        file = normalize(root .. "/" .. path),
                        status = code,
                    })
                end
            end
        end
    end
    return entries
end

function M.status(file, vcs)
    local root = M.root(file, vcs)
    if not root then
        return {}
    end
    local text
    if vcs == "git" then
        text = output(
            { "git", "status", "--porcelain", "--untracked-files=all" },
            root
        )
    elseif vcs == "hg" then
        text = output({ "hg", "status" }, root)
    else
        text = output({ "jj", "status" }, root)
    end
    return parse_status(vcs, text, root)
end

return M
