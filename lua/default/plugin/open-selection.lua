-- Setup Keybindings ------------------------------------------------------- {{{
local seditors = {}
local files_attached = {}
local file_autocmds = {}
local open_count = 0
local syncing = false
local syncing_origin = nil
local dirty = {}
local pending = {}
local reanchor = {}
local refresh_scheduled = false
local flush_scheduled = false

-- A visual selection reports its mode through mode() while the keymap runs,
-- and through visualmode() afterwards. Linewise is the safe fallback.
local function selection_type()
    local mode = vim.fn.mode()
    if mode == "v" or mode == "V" or mode == "\22" then
        return mode
    end
    local visual = vim.fn.visualmode()
    if visual ~= "" then
        return visual
    end
    return "V"
end

local function forget_sed(buf)
    seditors[buf] = nil
    dirty[buf] = nil
    pending[buf] = nil
    reanchor[buf] = nil
end

-- Locate the block of lines the seditor still holds inside the source file.
-- The block identifies itself, which avoids recomputing an interval when
-- another seditor or an external edit moved the lines around.
local function match_block(sed_bufnr, source)
    local content = vim.api.nvim_buf_get_lines(sed_bufnr, 0, -1, false)
    if #content == 0 then
        return nil
    end
    for i = 1, #source - #content + 1 do
        if source[i] == content[1] then
            local matched = true
            for j = 2, #content do
                if source[i + j - 1] ~= content[j] then
                    matched = false
                    break
                end
            end
            if matched then
                return i - 1
            end
        end
    end
    return nil
end

-- Source edits and reloads rebuild a seditor from its range in the file.
-- Whole range replacement stays correct when edits arrive faster than the
-- event loop turns, which a per line delta does not.
local function refresh_seditors()
    refresh_scheduled = false
    for sed_bufnr, sed in pairs(seditors) do
        -- A seditor with unflushed typing owns its range, so the source side
        -- must not overwrite it.
        if pending[sed_bufnr] then
            dirty[sed_bufnr] = nil
        elseif dirty[sed_bufnr] and vim.api.nvim_buf_is_valid(sed_bufnr) then
            dirty[sed_bufnr] = nil
            local source =
                vim.api.nvim_buf_get_lines(sed.file_bufnr, 0, -1, false)
            if reanchor[sed_bufnr] then
                reanchor[sed_bufnr] = nil
                local start = match_block(sed_bufnr, source)
                if start then
                    sed.firstline = start
                    sed.lastline = start
                        + vim.api.nvim_buf_line_count(sed_bufnr)
                end
            end
            local to = math.min(sed.lastline, #source)
            local new_lines = {}
            if sed.firstline < to then
                new_lines = vim.list_slice(source, sed.firstline + 1, to)
            end
            local was_syncing = syncing
            syncing = true
            vim.api.nvim_buf_set_lines(sed_bufnr, 0, -1, false, new_lines)
            syncing = was_syncing
            if #new_lines == 0 then
                forget_sed(sed_bufnr)
            end
        end
    end
end

local function schedule_refresh()
    if refresh_scheduled then
        return
    end
    refresh_scheduled = true
    vim.schedule(refresh_seditors)
end

-- Typing in a seditor writes its whole range into the source buffer. Writing
-- the full range instead of the captured event keeps every seditor of a file
-- in step, because the mapping is recomputed from the live range instead of
-- from positions that an earlier flush already moved.
local function flush_seditors()
    flush_scheduled = false
    refresh_seditors()
    for sed_bufnr, _ in pairs(pending) do
        pending[sed_bufnr] = nil
        local sed = seditors[sed_bufnr]
        if
            sed
            and vim.api.nvim_buf_is_valid(sed_bufnr)
            and vim.api.nvim_buf_is_valid(sed.file_bufnr)
        then
            local content = vim.api.nvim_buf_get_lines(sed_bufnr, 0, -1, false)
            syncing = true
            syncing_origin = sed_bufnr
            vim.api.nvim_buf_set_lines(
                sed.file_bufnr,
                sed.firstline,
                sed.lastline,
                false,
                content
            )
            sed.lastline = sed.firstline + #content
            syncing_origin = nil
            syncing = false
            vim.bo[sed.file_bufnr].modified = true
        end
    end
end

local function schedule_flush()
    if flush_scheduled then
        return
    end
    flush_scheduled = true
    vim.schedule(flush_seditors)
end

local function attach_file(buf)
    if files_attached[buf] then
        return
    end
    local ok = vim.api.nvim_buf_attach(buf, false, {
        on_lines = function(
            _,
            attached_buf,
            _,
            firstline,
            lastline,
            new_lastline
        )
            local delta = (new_lastline - firstline) - (lastline - firstline)
            local dirtied = false
            for sed_bufnr, sed in pairs(seditors) do
                if
                    sed.file_bufnr == attached_buf
                    and sed_bufnr ~= syncing_origin
                then
                    if lastline <= sed.firstline then
                        sed.firstline = sed.firstline + delta
                        sed.lastline = sed.lastline + delta
                    elseif firstline >= sed.lastline then
                        -- below the range, the seditor does not follow
                    elseif
                        firstline <= sed.firstline
                        and lastline >= sed.lastline
                    then
                        sed.firstline = firstline
                        sed.lastline = new_lastline
                        dirty[sed_bufnr] = true
                        dirtied = true
                    else
                        if lastline >= sed.lastline then
                            sed.lastline = math.min(sed.lastline, new_lastline)
                        else
                            sed.lastline = sed.lastline + delta
                        end
                        dirty[sed_bufnr] = true
                        reanchor[sed_bufnr] = true
                        dirtied = true
                    end
                end
            end
            if not syncing then
                vim.bo[attached_buf].modified = true
            end
            if dirtied then
                schedule_refresh()
            end
        end,
        on_detach = function(_, detached)
            files_attached[detached] = nil
        end,
    })
    -- The attach can fail while the buffer is not fully loaded during a
    -- reload, so only a real success marks the file as attached.
    if ok == false then
        files_attached[buf] = nil
        return false
    end
    files_attached[buf] = true
end

-- A reload re-anchors each seditor on the block of lines it still holds, so a
-- file that shifted on disk keeps pointing at the right range. The fallback
-- keeps the old line numbers, clamped to the new file length.
local function reanchor_seditors(buf)
    local source = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    for sed_bufnr, sed in pairs(seditors) do
        if sed.file_bufnr ~= buf then
            goto continue
        end
        local start = match_block(sed_bufnr, source)
        if start then
            sed.firstline = start
            sed.lastline = start + vim.api.nvim_buf_line_count(sed_bufnr)
        else
            sed.lastline = math.min(sed.lastline, #source)
        end
        dirty[sed_bufnr] = true
        ::continue::
    end
end

-- A reload drops the buffer attach, so reconnect it and rebuild each seditor
-- from the reloaded content.
local function watch_file_reloads(buf)
    if file_autocmds[buf] then
        return
    end
    file_autocmds[buf] = true
    vim.api.nvim_create_autocmd({ "BufReadPost", "BufFilePost" }, {
        buffer = buf,
        callback = function()
            vim.schedule(function()
                if not vim.api.nvim_buf_is_valid(buf) then
                    return
                end
                attach_file(buf)
                reanchor_seditors(buf)
                refresh_seditors()
            end)
        end,
    })
end

local function open_selection(command)
    local lines = vim.fn.getregion(
        vim.fn.getpos "v",
        vim.fn.getpos ".",
        { type = selection_type() }
    )
    local file_bufnr = vim.api.nvim_get_current_buf()
    local path = vim.api.nvim_buf_get_name(file_bufnr)
    local filetype = vim.bo[file_bufnr].filetype
    local firstline = math.min(vim.fn.getpos("v")[2], vim.fn.getpos(".")[2])
    local lastline = math.max(vim.fn.getpos("v")[2], vim.fn.getpos(".")[2])

    vim.cmd(command)
    local buf = vim.api.nvim_create_buf(true, false)

    open_count = open_count + 1
    vim.api.nvim_buf_set_name(buf, ("%s.seditor.%d"):format(path, open_count))
    -- The seditor carries no LSP client of its own. The native attach callback
    -- skips every buftype other than empty, so buftype acwrite keeps the
    -- fragment out of the server while routing :w to BufWriteCmd.
    vim.bo[buf].buftype = "acwrite"
    vim.bo[buf].filetype = filetype
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].swapfile = false

    vim.api.nvim_win_set_buf(0, buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modified = false

    seditors[buf] = {
        file_bufnr = file_bufnr,
        firstline = firstline - 1,
        lastline = lastline,
    }
    attach_file(file_bufnr)
    watch_file_reloads(file_bufnr)

    -- A keystroke marks the seditor dirty, and the flush writes the range.
    -- The write waits for the event loop because textlock is active inside
    -- on_lines, the same reason the seditor sync of yode-nvim schedules it.
    vim.api.nvim_buf_attach(buf, false, {
        on_lines = function(_, attached_buf)
            -- Programmatic writes set syncing, so only real typing marks the
            -- seditor pending and the loop between overlapping seditors stops.
            if not seditors[attached_buf] or syncing then
                return
            end
            pending[attached_buf] = true
            schedule_flush()
        end,
        on_detach = function(_, detached)
            forget_sed(detached)
        end,
    })

    -- Saving writes the source file the way yode-nvim does, because the
    -- source buffer already holds the edited range.
    vim.api.nvim_create_autocmd("BufWriteCmd", {
        buffer = buf,
        callback = function()
            pending[buf] = true
            flush_seditors()
            pcall(
                vim.api.nvim_buf_call,
                seditors[buf] and seditors[buf].file_bufnr or buf,
                function()
                    vim.cmd "silent write"
                end
            )
            vim.bo[buf].modified = false
        end,
    })

    return buf
end

vim.keymap.set({ "v", "x" }, "<Leader>yt", function()
    open_selection "tabnew"
end, { desc = "Open Selection in New Tab" })

vim.keymap.set({ "v", "x" }, "<Leader>ys", function()
    open_selection "new"
end, { desc = "Open Selection in Horizontal Split" })

vim.keymap.set({ "v", "x" }, "<Leader>yv", function()
    open_selection "vnew"
end, { desc = "Open Selection in Vertical Split" })

return { open_selection = open_selection }
-- }}}
