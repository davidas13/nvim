-- Setup ------------------------------------------------------------------- {{{
-- Module reference for the declaration under the cursor, built from the LSP
-- symbol tree and the file's own path. Languages with no module concept, and
-- buffers where no server answers textDocument/documentSymbol, produce nothing.

local M = {}

-- LSP SymbolKind values that name a navigable declaration. Object, module, and
-- variable prefixes carry no module meaning, as with the Lua `M` table that
-- lua_ls reports as kind 19.
local declaration_kinds = {
    [3] = true, -- Namespace
    [5] = true, -- Class
    [6] = true, -- Method
    [10] = true, -- Enum
    [11] = true, -- Interface
    [12] = true, -- Function
    [23] = true, -- Struct
}

-- Bound for the synchronous symbol request. The first request on a cold server
-- measured around one second here, warm ones under five milliseconds, so the
-- wait lands once per buffer.
local request_timeout_ms = 1200

-- Per filetype module layout. Two modes exist: with package_marker the path
-- walks up while a directory carries that marker, as a Python package; without
-- it the path is taken relative to the project root.
local specs = {
    python = {
        root_markers = {
            "pyproject.toml",
            "setup.py",
            "setup.cfg",
            "Pipfile",
            ".git",
        },
        package_marker = "__init__.py",
        sep = ".",
        dotted = true,
        import = function(module_path, symbol)
            return ("from %s import %s"):format(module_path, symbol)
        end,
    },
    lua = {
        root_markers = { ".luarc.json", ".luacheckrc", ".git" },
        drop_prefix = "lua",
        drop_files = { "init.lua" },
        sep = ".",
        dotted = true,
        import = function(module_path, symbol)
            return ("local %s = require(\"%s\")"):format(symbol, module_path)
        end,
    },
    rust = {
        root_markers = { "Cargo.toml", ".git" },
        drop_dirs = { "src" },
        drop_files = { "mod.rs", "lib.rs", "main.rs" },
        crate_marker = "Cargo.toml",
        sep = "::",
        import = function(module_path, symbol)
            return ("use %s::%s;"):format(module_path, symbol)
        end,
    },
    typescript = {
        root_markers = {
            "tsconfig.json",
            "jsconfig.json",
            "package.json",
            ".git",
        },
        sep = "/",
        import = function(module_path, symbol)
            return ("import { %s } from \"%s\""):format(symbol, module_path)
        end,
    },
    zig = {
        root_markers = { "build.zig", ".git" },
        drop_dirs = { "src" },
        keep_ext = true,
        sep = ".",
        import = function(module_path, symbol)
            return ("const %s = @import(\"%s\");"):format(symbol, module_path)
        end,
    },
    c = {
        root_markers = {
            "compile_commands.json",
            "CMakeLists.txt",
            "Makefile",
            ".git",
        },
        drop_dirs = { "src", "include" },
        keep_ext = true,
        sep = "/",
        header_only = { ".h", ".hh", ".hpp", ".hxx" },
        import = function(module_path)
            return ("#include \"%s\""):format(module_path)
        end,
    },
    cpp = {
        root_markers = {
            "compile_commands.json",
            "CMakeLists.txt",
            "Makefile",
            ".git",
        },
        drop_dirs = { "src", "include" },
        keep_ext = true,
        sep = "/",
        header_only = { ".h", ".hh", ".hpp", ".hxx" },
        import = function(module_path)
            return ("#include \"%s\""):format(module_path)
        end,
    },
}

local function is_dir(path)
    local stat = vim.uv.fs_stat(path)
    return stat ~= nil and stat.type == "directory"
end

local function has_file(dir, name)
    return vim.uv.fs_stat(vim.fs.joinpath(dir, name)) ~= nil
end

-- Nearest ancestor directory holding one of the markers. A file opened outside
-- any project gets its own directory as the boundary.
local function project_root(spec, path)
    local dir = vim.fs.dirname(vim.fs.normalize(path))
    while dir do
        for _, marker in ipairs(spec.root_markers) do
            if has_file(dir, marker) then
                return dir
            end
        end
        local parent = vim.fs.dirname(dir)
        if parent == dir then
            return nil
        end
        dir = parent
    end
    return nil
end

local function crate_name(root)
    local manifest = vim.fs.joinpath(root, "Cargo.toml")
    local ok, lines = pcall(vim.fn.readfile, manifest)
    if not ok then
        return nil
    end
    for _, line in ipairs(lines) do
        local name = line:match "^%s*name%s*=%s*\"([^\"]+)\""
        if name then
            return name
        end
    end
    return nil
end

-- Directory parts of the module path, walking a package marker or taking the
-- plain relative path, then dropping the prefixes a language does not spell.
local function directory_parts(spec, path, root)
    local dir = vim.fs.dirname(path)
    local rel = dir:sub(#root + 2)
    local parts = {}
    if spec.package_marker then
        while dir ~= root and has_file(dir, spec.package_marker) do
            table.insert(parts, 1, vim.fs.basename(dir))
            dir = vim.fs.dirname(dir)
        end
    else
        for part in vim.gsplit(rel, "/", { plain = true }) do
            if
                part ~= "" and not vim.tbl_contains(spec.drop_dirs or {}, part)
            then
                parts[#parts + 1] = part
            end
        end
        if spec.drop_prefix and parts[1] == spec.drop_prefix then
            table.remove(parts, 1)
        end
    end
    return parts
end

local function module_path(spec, path)
    local root = project_root(spec, path)
    if not root then
        return nil
    end
    local base = vim.fs.basename(path)
    local stem = base:match "^(.-)%.([^%.]+)$"
    local parts = directory_parts(spec, path, root)
    local package_itself = spec.package_marker and base == spec.package_marker
        or vim.tbl_contains(spec.drop_files or {}, base)
    if not package_itself then
        parts[#parts + 1] = spec.keep_ext and base or (stem or base)
    end
    if spec.crate_marker then
        local crate = crate_name(root)
        if crate then
            table.insert(parts, 1, crate)
        end
    end
    if vim.tbl_isempty(parts) then
        return nil
    end
    return table.concat(parts, spec.sep)
end

-- Declaration under the cursor from the symbol tree. The full range decides
-- containment because every server observed here puts the selection range on
-- the signature line only, and a cursor in the body falls outside it.
local function symbol_at_cursor(symbols, row, col)
    local function contains(symbol)
        local range = symbol.range
        if not range then
            return false
        end
        if row < range.start.line or row > range["end"].line then
            return false
        end
        if row == range.start.line and col < range.start.character then
            return false
        end
        return not (row == range["end"].line and col > range["end"].character)
    end

    -- Descends with the dotted prefix in hand and returns the deepest
    -- declaration. A non declaration ancestor such as the Lua `M` table drops
    -- out of the prefix, and a parameter or local inside the body loses to the
    -- enclosing function instead of appending a trailing `name`.
    local function walk(list, prefix)
        local best
        for _, symbol in ipairs(list) do
            if contains(symbol) then
                local qualified = prefix
                if declaration_kinds[symbol.kind] then
                    -- The last dot segment only: lua_ls reports a function
                    -- declared in a table as `M.hello` in the name itself.
                    local name = symbol.name:match "[^%.]+$" or symbol.name
                    qualified = prefix and (prefix .. "." .. name) or name
                    best = qualified
                end
                local nested = symbol.children
                    and walk(symbol.children, qualified)
                if nested then
                    return nested
                end
            end
        end
        return best
    end

    return walk(symbols, nil)
end

-- API -------------------------------------------------------------------- {{{

---Module reference items for the current buffer, empty when the language has
---no module layout or no server answers.
---@param ctx table result of copy_location.capture
---@return table[]
function M.items(ctx)
    local spec = specs[ctx.filetype]
    if not spec then
        return {}
    end
    local path = vim.api.nvim_buf_get_name(ctx.bufnr)
    if path == "" then
        return {}
    end
    local suffix = path:match "%.([^%.]+)$"
    if
        spec.header_only
        and not vim.tbl_contains(spec.header_only, "." .. (suffix or ""))
    then
        return {}
    end

    local clients = vim.lsp.get_clients {
        bufnr = ctx.bufnr,
        method = "textDocument/documentSymbol",
    }
    if #clients == 0 then
        return {}
    end

    -- Guarded so a server that supports the method but answers nothing, as
    -- bashls does, costs one bounded wait instead of a visible freeze.
    local response =
        vim.lsp.buf_request_sync(ctx.bufnr, "textDocument/documentSymbol", {
            textDocument = { uri = vim.uri_from_fname(path) },
        }, request_timeout_ms)

    local symbols
    for _, entry in pairs(response or {}) do
        if entry.result and #entry.result > 0 then
            symbols = entry.result
            break
        end
    end
    if not symbols then
        return {}
    end

    local symbol = symbol_at_cursor(symbols, ctx.row - 1, ctx.col)
    if not symbol then
        return {}
    end

    local path_parts = module_path(spec, path)
    if not path_parts then
        return {}
    end

    local items = {}
    if spec.dotted then
        local value = path_parts .. spec.sep .. symbol
        items[#items + 1] = {
            label = "MODULE",
            value = value,
            text = "MODULE  " .. value,
        }
    end
    if spec.import then
        local value = spec.import(path_parts, symbol)
        items[#items + 1] = {
            label = "IMPORT",
            value = value,
            text = "IMPORT  " .. value,
        }
    end
    return items
end
-- }}}

return M
