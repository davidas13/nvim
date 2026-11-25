-- Setup ------------------------------------------------------------------- {{{
-- Copy the unified diff of every pair of diff-mode windows to the clipboard,
-- with the changed regions highlighted in each buffer at word granularity.

local M = {}

local ns = vim.api.nvim_create_namespace "copydiff_hl"

-- Highlight groups (change the colors to your liking)
vim.api.nvim_set_hl(
    0,
    "CopyDiffDel",
    { bg = "#6e2b2b", fg = "#ffb3b3", bold = true }
)
vim.api.nvim_set_hl(
    0,
    "CopyDiffAdd",
    { bg = "#2b6e3a", fg = "#b3ffc4", bold = true }
)

-- One entry per distinct buffer of the diff-mode windows, so a buffer shown in
-- two of them is never compared against itself and is compared against a third
-- buffer once.
local function diff_windows()
    local wins = vim.tbl_filter(function(id)
        return vim.wo[id].diff
    end, vim.api.nvim_tabpage_list_wins(0))

    local seen, sides = {}, {}
    for _, win in ipairs(wins) do
        local buf = vim.api.nvim_win_get_buf(win)
        if not seen[buf] then
            seen[buf] = true
            local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
            local name = vim.api.nvim_buf_get_name(buf)
            sides[#sides + 1] = {
                buf = buf,
                lines = lines,
                -- A trailing newline keeps the last line counted, so the
                -- 1-based line numbers vim.diff reports index straight into
                -- lines.
                text = table.concat(lines, "\n") .. "\n",
                label = name ~= "" and name or ("buffer " .. buf),
            }
        end
    end
    return sides
end

-- Split a string into tokens: a word, a run of whitespace, or a single symbol
local function tokenize(s)
    local tokens, pos = {}, 1
    while pos <= #s do
        local a, b = s:find("^[%w_]+", pos)
        if not a then
            a, b = s:find("^%s+", pos)
        end
        if not a then
            -- single character (UTF-8 aware)
            local ch = s:match("^[%z\1-\127\194-\244][\128-\191]*", pos)
            a, b = pos, pos + #ch - 1
        end
        tokens[#tokens + 1] = { text = s:sub(a, b), start = a - 1, stop = b }
        pos = b + 1
    end
    -- An empty line has to yield one empty token, because vim.diff still sees
    -- the line its newline creates and would report it as changed.
    if #tokens == 0 then
        tokens[1] = { text = "", start = 0, stop = 0 }
    end
    return tokens
end

local function join_tokens(tokens)
    local texts = {}
    for index, token in ipairs(tokens) do
        texts[index] = token.text
    end
    return table.concat(texts, "\n") .. "\n"
end

-- Compute the differing byte ranges between two lines (word level)
local function word_diff(l1, l2)
    local t1, t2 = tokenize(l1 or ""), tokenize(l2 or "")
    local hunks = vim.diff(
        join_tokens(t1),
        join_tokens(t2),
        { result_type = "indices", algorithm = "myers" }
    )

    local r1, r2 = {}, {}
    for _, h in ipairs(hunks) do
        local sa, ca, sb, cb = h[1], h[2], h[3], h[4]
        if ca > 0 then
            r1[#r1 + 1] = { t1[sa].start, t1[sa + ca - 1].stop }
        end
        if cb > 0 then
            r2[#r2 + 1] = { t2[sb].start, t2[sb + cb - 1].stop }
        end
    end
    return r1, r2
end

-- Apply a highlight group to a list of byte ranges on a given line
local function hl_ranges(buf, lnum, ranges, group)
    for _, r in ipairs(ranges) do
        vim.api.nvim_buf_set_extmark(buf, ns, lnum, r[1], {
            end_col = r[2],
            hl_group = group,
            priority = 200,
        })
    end
end

-- Highlight whole lines, first is the 1-based line number vim.diff reports and
-- count the length of the run.
local function hl_lines(side, first, count, group)
    for offset = 0, count - 1 do
        local index = first + offset
        hl_ranges(
            side.buf,
            index - 1,
            { { 0, #(side.lines[index] or "") } },
            group
        )
    end
end

-- Highlight one hunk across both sides. Paired lines are marked word by word,
-- and the leftover lines of the longer side cover the whole line.
local function hl_hunk(h, left, right)
    local sa, ca, sb, cb = h[1], h[2], h[3], h[4]
    local paired = math.min(ca, cb)
    for offset = 0, paired - 1 do
        local r1, r2 =
            word_diff(left.lines[sa + offset], right.lines[sb + offset])
        hl_ranges(left.buf, sa + offset - 1, r1, "CopyDiffDel")
        hl_ranges(right.buf, sb + offset - 1, r2, "CopyDiffAdd")
    end
    if ca > cb then
        hl_lines(left, sa + paired, ca - cb, "CopyDiffDel")
    elseif cb > ca then
        hl_lines(right, sb + paired, cb - ca, "CopyDiffAdd")
    end
end

-- API -------------------------------------------------------------------- {{{

---Copy the diff and highlight the changed regions in every diff buffer.
function M.copy()
    local sides = diff_windows()

    if #sides < 2 then
        vim.notify(
            "Run :windo diffthis on at least 2 buffers first!",
            vim.log.levels.ERROR
        )
        return
    end

    -- Every comparison starts from clean marks, so a run that changes nothing
    -- also drops the marks of the run before it.
    for _, side in ipairs(sides) do
        vim.api.nvim_buf_clear_namespace(side.buf, ns, 0, -1)
    end

    local parts, differing = {}, false
    for i = 1, #sides - 1 do
        for j = i + 1, #sides do
            local left, right = sides[i], sides[j]
            local hunks =
                vim.diff(left.text, right.text, { result_type = "indices" })
            if #hunks > 0 then
                differing = true
                for _, h in ipairs(hunks) do
                    hl_hunk(h, left, right)
                end
                -- A single pair is unambiguous on its own, several are not.
                if #sides > 2 then
                    parts[#parts + 1] = ("--- %s vs %s"):format(
                        left.label,
                        right.label
                    )
                end
                parts[#parts + 1] = vim.diff(left.text, right.text)
            end
        end
    end

    if not differing then
        vim.notify("No differences found.", vim.log.levels.INFO)
        return
    end

    vim.fn.setreg("+", table.concat(parts, "\n"))
    vim.notify(
        "Diff copied to clipboard and differences highlighted!",
        vim.log.levels.INFO
    )
end

---Remove every highlight placed by M.copy.
function M.clear()
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
        vim.api.nvim_buf_clear_namespace(b, ns, 0, -1)
    end
    vim.notify("Diff highlights cleared.", vim.log.levels.INFO)
end
-- }}}

return M
