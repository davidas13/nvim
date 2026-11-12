-- Setup ------------------------------------------------------------------- {{{
-- Copy a reference to the current cursor position: path, enclosing scope, and
-- line, in the combinations editors and terminals can consume.

local M = {}

-- Node types carrying a navigable name. Matched as plain substrings so grammar
-- spellings such as function_definition and method_declaration both hit.
local scope_types =
    { "function", "method", "class", "impl", "interface", "trait", "struct" }

-- Child types holding the scope name when the grammar keeps it outside a
-- "name" field, as in Lua dot_index_expression for `function M.build`.
local name_children = {
    identifier = true,
    dot_index_expression = true,
    type_identifier = true,
}

-- Path formats and how a scope or line suffix attaches to each. A URI carries
-- a line only, since a protocol URL has no place for a symbol name.
local path_formats = {
    { key = "abs", label = "PATH", scope_sep = "::", line_sep = ":" },
    { key = "rel", label = "PATH (CWD)", scope_sep = "::", line_sep = ":" },
    { key = "base", label = "FILENAME", scope_sep = "::", line_sep = ":" },
    { key = "uri", label = "URI", scope_sep = nil, line_sep = "#L" },
}

-- Suffix combinations per format, ordered so the plain path comes first and
-- the most qualified variant comes last.
local combos = {
    { scope = false, line = false },
    { scope = true, line = false },
    { scope = false, line = true },
    { scope = true, line = true },
}

local function is_scope_type(node_type)
    for _, scope_type in ipairs(scope_types) do
        if node_type:find(scope_type, 1, true) then
            return true
        end
    end
    return false
end

local function node_name(node, bufnr)
    for child, field in node:iter_children() do
        if field == "name" then
            return vim.treesitter.get_node_text(child, bufnr)
        end
    end
    for child in node:iter_children() do
        if name_children[child:type()] then
            return vim.treesitter.get_node_text(child, bufnr)
        end
    end
    return nil
end

-- Nearest scope first, reversed before joining so the outer declaration leads.
local function scope_chain(pos, bufnr)
    local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
    if not ok or not parser then
        return nil
    end
    -- The highlighter parses in the background, so this read forces the tree it
    -- needs instead of racing it. A cursor moved seconds later pays nothing.
    parser:parse(true)
    local has_node, node =
        pcall(vim.treesitter.get_node, { bufnr = bufnr, pos = pos })
    if not has_node or not node then
        return nil
    end
    local chain = {}
    while node do
        if is_scope_type(node:type()) then
            local name = node_name(node, bufnr)
            if name then
                chain[#chain + 1] = name
            end
        end
        node = node:parent()
    end
    if vim.tbl_isempty(chain) then
        return nil
    end
    local outer_first = {}
    for i = #chain, 1, -1 do
        outer_first[#outer_first + 1] = chain[i]
    end
    return table.concat(outer_first, ".")
end

-- Modes where a selection exists, so a line range can be derived from it.
local visual_modes = { v = true, V = true, ["\22"] = true }

-- Selection bounds as 1-based lines. The anchor and the cursor swap places when
-- the selection runs upward, so take the extremes instead of assuming an order.
local function selection_lines()
    local mode = vim.fn.mode()
    if not visual_modes[mode] then
        return nil
    end
    local anchor = vim.fn.getpos "v"
    local cursor = vim.fn.getpos "."
    local first = math.min(anchor[2], cursor[2])
    local last = math.max(anchor[2], cursor[2])
    return first, last
end

local function capture()
    local bufnr = vim.api.nvim_get_current_buf()
    local abs = vim.fn.expand "%:p"
    if abs == "" then
        return nil
    end
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row, col = cursor[1], cursor[2]
    local first, last = selection_lines()
    local ctx = {
        bufnr = bufnr,
        row = row,
        col = col,
        abs = abs,
        rel = vim.fn.fnamemodify(abs, ":."),
        base = vim.fn.fnamemodify(abs, ":t"),
        uri = vim.uri_from_fname(abs),
        -- A missing parser or a cursor outside any scope both leave the symbol
        -- suffixes out instead of failing the whole action.
        scope = scope_chain({ row - 1, col }, bufnr),
    }
    if first then
        ctx.first, ctx.last = first, last
    end
    return ctx
end

local function line_reference(ctx)
    if ctx.first == nil then
        return ctx.row
    end
    if ctx.first == ctx.last then
        return ctx.first
    end
    return ("%d-%d"):format(ctx.first, ctx.last)
end

local function build_items(ctx)
    local items = {}
    local line_ref = line_reference(ctx)
    for _, fmt in ipairs(path_formats) do
        for _, combo in ipairs(combos) do
            local scope_suffix, label = "", fmt.label
            if combo.scope then
                if not (ctx.scope and fmt.scope_sep) then
                    goto skipped
                end
                scope_suffix = fmt.scope_sep .. ctx.scope
                label = label .. " :: " .. ctx.scope
            end
            if combo.line then
                scope_suffix = scope_suffix .. fmt.line_sep .. line_ref
                label = label .. " : " .. line_ref
            end
            local value = ctx[fmt.key] .. scope_suffix
            items[#items + 1] = {
                text = label .. "  " .. value,
                label = label,
                value = value,
                file = ctx.abs,
                pos = { ctx.row, ctx.col },
            }
            ::skipped::
        end
    end
    return items
end

local function yank(value)
    vim.fn.setreg("+", value)
    vim.fn.setreg("\"", value)
    local ok, snacks = pcall(require, "snacks")
    if ok and snacks.notify then
        snacks.notify.info("Copied " .. value)
    else
        vim.notify("Copied " .. value)
    end
end

-- API -------------------------------------------------------------------- {{{

---Open the picker with every path, scope, and line combination.
function M.pick()
    -- Captured before the picker opens, while the current buffer still holds
    -- the cursor position and the treesitter tree to walk.
    local ctx = capture()
    if not ctx then
        vim.notify("No file in the current buffer", vim.log.levels.WARN)
        return
    end
    local items = build_items(ctx)
    local ok, snacks = pcall(require, "snacks")
    if ok and snacks.picker then
        snacks.picker {
            title = "Copy Reference",
            -- Matches the vim.ui.select shape: floating, one input line above the
            -- list, no preview pane.
            layout = "select",
            items = items,
            format = function(item)
                return {
                    { item.label, "SnacksPickerLabel" },
                    { "  " },
                    { item.value, "Comment" },
                }
            end,
            confirm = function(picker, item)
                picker:close()
                yank(item.value)
            end,
        }
        return
    end
    vim.ui.select(items, {
        prompt = "Copy Reference",
        format_item = function(item)
            return item.text
        end,
    }, function(item)
        if item then
            yank(item.value)
        end
    end)
end

---Copy one path format straight to the clipboard, without opening the picker.
---@param key "abs" | "rel" | "base" | "uri"
function M.copy(key)
    local ctx = capture()
    if not ctx then
        vim.notify("No file in the current buffer", vim.log.levels.WARN)
        return
    end
    yank(ctx[key])
end
-- }}}

return M
