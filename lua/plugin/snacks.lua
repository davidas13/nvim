-- ==== Intallation ===========================================================
--
vim.pack.add {
    { src = "https://github.com/nvim-lua/plenary.nvim" },
    { src = "https://github.com/folke/todo-comments.nvim" },

    -- Main plugin.
    { src = "https://github.com/folke/snacks.nvim" },
}

-- ==== Setup =================================================================
--
local snacks = require "snacks"

snacks.setup {
    input = { enabled = true },
    debug = { enabled = true },
    explorer = {
        replace_netrw = true,
    },
    bufdelete = { enabled = true },
    indent = {
        animate = { animate = false },
    },
    picker = {
        layout = "custom",
        layouts = {
            custom = {
                layout = {
                    box = "vertical",
                    backdrop = false,
                    row = -1,
                    width = 0,
                    height = 0.6,
                    border = "none",
                    title = " {title} {live} {flags}",
                    title_pos = "left",
                    {
                        box = "horizontal",
                        { win = "list", border = "rounded" },
                        { win = "preview", title = "{preview}", width = 0.6, border = "rounded" },
                    },
                    { win = "input", height = 1, border = "bottom" },
                },
            },
        },
        ui_select = true,
        icons = {
            git = {
                staged = "●",
                added = "A",
                deleted = "D",
                ignored = "",
                modified = "M",
                renamed = "R",
                untracked = "U",
            },
        },
        win = {
            list = {
                wo = {
                    number = true,
                    relativenumber = true,
                    numberwidth = 3,
                },
            },
            input = {},
        },
        sources = {
            explorer = {
                focus = "list",
                ignored = true,
                hidden = true,
                cycle = true,
                auto_close = true,
                diagnostics = true,
                watch = true,
                git_status = true,
                git_untracked = true,
                jump = {
                    close = true,
                },
                layout = "custom",
                win = {
                    list = {
                        keys = {
                            ["y"] = "copy_file_path",
                            ["s"] = "search_in_directory",
                            ["D"] = "diff",
                        },
                    },
                },
                -- source: https://ricoberger.de/blog/posts/neovim-extend-snacks-nvim-explorer/
                actions = {
                    copy_file_path = {
                        action = function(_, item)
                            if not item then
                                return
                            end

                            local vals = {
                                ["BASENAME"] = vim.fn.fnamemodify(item.file, ":t:r"),
                                ["EXTENSION"] = vim.fn.fnamemodify(item.file, ":t:e"),
                                ["FILENAME"] = vim.fn.fnamemodify(item.file, ":t"),
                                ["PATH"] = item.file,
                                ["PATH (CWD)"] = vim.fn.fnamemodify(item.file, ":."),
                                ["PATH (HOME)"] = vim.fn.fnamemodify(item.file, ":~"),
                                ["URI"] = vim.uri_from_fname(item.file),
                            }

                            local options = vim.tbl_filter(function(val)
                                return vals[val] ~= ""
                            end, vim.tbl_keys(vals))
                            if vim.tbl_isempty(options) then
                                vim.notify("No values to copy", vim.log.levels.WARN)
                                return
                            end
                            table.sort(options)
                            vim.ui.select(options, {
                                prompt = "Choose to copy to clipboard:",
                                format_item = function(list_item)
                                    return ("%s: %s"):format(list_item, vals[list_item])
                                end,
                            }, function(choice)
                                local result = vals[choice]
                                if result then
                                    vim.fn.setreg("+", result)
                                    Snacks.notify.info("Yanked `" .. result .. "`")
                                end
                            end)
                        end,
                    },
                    search_in_directory = {
                        action = function(_, item)
                            if not item then
                                return
                            end
                            local dir = vim.fn.fnamemodify(item.file, ":p:h")
                            Snacks.picker.grep {
                                cwd = dir,
                                cmd = "rg",
                                args = {
                                    "-g",
                                    "!.git",
                                    "-g",
                                    "!node_modules",
                                    "-g",
                                    "!dist",
                                    "-g",
                                    "!build",
                                    "-g",
                                    "!coverage",
                                    "-g",
                                    "!.DS_Store",
                                    "-g",
                                    "!.docusaurus",
                                    "-g",
                                    "!.dart_tool",
                                },
                                show_empty = true,
                                hidden = true,
                                ignored = true,
                                follow = false,
                                supports_live = true,
                            }
                        end,
                    },
                    diff = {
                        action = function(picker)
                            picker:close()
                            local sel = picker:selected()
                            if #sel > 0 and sel then
                                Snacks.notify.info(sel[1].file)
                                vim.cmd("tabnew " .. sel[1].file)
                                vim.cmd("vert diffs " .. sel[2].file)
                                Snacks.notify.info("Diffing " .. sel[1].file .. " against " .. sel[2].file)
                                return
                            end

                            Snacks.notify.info "Select two entries for the diff"
                        end,
                    },
                },
            },
        },
    },
    ---@class snacks.notifier.Config
    notifier = {
        timeout = 2000, -- default timeout in ms
        width = { min = 60, max = 0.4 },
        height = { min = 1, max = 0.6 },
        -- editor margin to keep free. tabline and statusline are taken into account automatically
        margin = { top = 1, right = 1, bottom = 0 },
        padding = true, -- add 1 cell of left/right padding to the notification window
        sort = { "level", "added" }, -- sort by level and time
        -- minimum log level to display. TRACE is the lowest
        -- all notifications are stored in history
        level = vim.log.levels.TRACE,
        icons = {
            error = " ",
            warn = " ",
            info = " ",
            debug = " ",
            trace = " ",
        },
        keep = function(_)
            return vim.fn.getcmdpos() > 0
        end,
        ---@type snacks.notifier.style
        style = "minimal",
        top_down = true, -- place notifications from top to bottom
        date_format = "%R", -- time format for notifications
        -- format for footer when more lines are available
        -- `%d` is replaced with the number of lines.
        -- only works for styles with a border
        ---@type string|boolean
        more_format = " ↓ %d lines ",
        refresh = 30, -- refresh at most every 50ms
    },
    toggle = {
        map = vim.keymap.set, -- keymap.set function to use
        which_key = true, -- integrate with which-key to show enabled/disabled icons and colors
        notify = true, -- show a notification when toggling
        -- icons for enabled/disabled states
        icon = {
            enabled = " ",
            disabled = " ",
        },
        -- colors for enabled/disabled states
        color = {
            enabled = "green",
            disabled = "yellow",
        },
        wk_desc = {
            enabled = "Disable ",
            disabled = "Enable ",
        },
    },
}

-- ==== Setup Keybindings =====================================================
--
vim.keymap.set("n", "<leader>e", function()
    snacks.explorer()
end, { silent = true, desc = "File Explorer (cwd)", noremap = true })

vim.keymap.set({ "n" }, "<leader>sg", function()
    snacks.picker.grep()
end, { silent = true, desc = "Grep Files", noremap = true })

vim.keymap.set({ "n" }, "<leader>sb", function()
    snacks.picker.grep_buffers()
end, { silent = true, desc = "Grep Buffers", noremap = true })

vim.keymap.set({ "n" }, "<leader>sl", function()
    snacks.picker.lines()
end, { silent = true, desc = "Buffer Lines", noremap = true })

vim.keymap.set({ "n", "x" }, "<leader>sw", function()
    snacks.picker.grep_word()
end, { silent = true, desc = "Visual selection or word", noremap = true })

vim.keymap.set({ "n" }, "<leader>st", function()
    snacks.picker.todo_comments()
end, { silent = true, desc = "TODO", noremap = true })

vim.keymap.set({ "n" }, "<leader>s:", function()
    snacks.picker.command_history()
end, { silent = true, desc = "Command History", noremap = true })

vim.keymap.set({ "n" }, "<leader>s\"", function()
    snacks.picker.registers()
end, { silent = true, desc = "Registers", noremap = true })

vim.keymap.set({ "n" }, "<leader>s/", function()
    snacks.picker.search_history()
end, { silent = true, desc = "Search History", noremap = true })

vim.keymap.set({ "n" }, "<leader>sa", function()
    snacks.picker.autocmds()
end, { silent = true, desc = "Autocmds", noremap = true })

vim.keymap.set({ "n" }, "<leader>sc", function()
    snacks.picker.commands()
end, { silent = true, desc = "Commands", noremap = true })

vim.keymap.set({ "n" }, "<leader>sd", function()
    snacks.picker.diagnostics()
end, { silent = true, desc = "Diagnostics", noremap = true })

vim.keymap.set({ "n" }, "<leader>sD", function()
    snacks.picker.diagnostics_buffer()
end, { silent = true, desc = "Buffer Diagnostics", noremap = true })

vim.keymap.set({ "n" }, "<leader>sh", function()
    snacks.picker.help()
end, { silent = true, desc = "Help Pages", noremap = true })

vim.keymap.set({ "n" }, "<leader>sH", function()
    snacks.picker.highlights()
end, { silent = true, desc = "Highlights", noremap = true })

vim.keymap.set({ "n" }, "<leader>si", function()
    snacks.picker.icons()
end, { silent = true, desc = "Icons", noremap = true })

vim.keymap.set({ "n" }, "<leader>sj", function()
    snacks.picker.jumps()
end, { silent = true, desc = "Jumps", noremap = true })

vim.keymap.set({ "n" }, "<leader>sk", function()
    snacks.picker.keymaps()
end, { silent = true, desc = "Keymaps", noremap = true })

vim.keymap.set({ "n" }, "<leader>sL", function()
    snacks.picker.loclist()
end, { silent = true, desc = "Location List", noremap = true })

vim.keymap.set({ "n" }, "<leader>sM", function()
    snacks.picker.man()
end, { silent = true, desc = "Man Pages", noremap = true })

vim.keymap.set({ "n" }, "<leader>sm", function()
    snacks.picker.marks()
end, { silent = true, desc = "Marks", noremap = true })

vim.keymap.set({ "n" }, "<leader>sR", function()
    snacks.picker.resume()
end, { silent = true, desc = "Resume", noremap = true })

vim.keymap.set({ "n" }, "<leader>sq", function()
    snacks.picker.qflist()
end, { silent = true, desc = "Quickfix List", noremap = true })

vim.keymap.set({ "n" }, "<leader>su", function()
    snacks.picker.undo()
end, { silent = true, desc = "Undotree", noremap = true })

vim.keymap.set({ "n" }, "<leader>sf", function()
    snacks.picker.smart()
end, { silent = true, desc = "Smart", noremap = true })

vim.keymap.set({ "n" }, "<leader>sn", function()
    snacks.picker.notifications()
end, { silent = true, desc = "Notification History", noremap = true })

vim.keymap.set({ "n" }, "<leader>fb", function()
    snacks.picker.buffers()
end, { silent = true, desc = "Buffers", noremap = true })

vim.keymap.set({ "n" }, "<leader>fc", function()
    snacks.picker.files { cwd = vim.fn.stdpath "config" }
end, { silent = true, desc = "Find Config File", noremap = true })

vim.keymap.set({ "n" }, "<leader>ff", function()
    snacks.picker.files()
end, { silent = true, desc = "Find Files", noremap = true })

vim.keymap.set({ "n" }, "<leader>fg", function()
    snacks.picker.git_files()
end, { silent = true, desc = "Find Git Files", noremap = true })

vim.keymap.set({ "n" }, "<leader>fp", function()
    snacks.picker.projects()
end, { silent = true, desc = "Projects", noremap = true })

vim.keymap.set({ "n" }, "<leader>fr", function()
    snacks.picker.recent()
end, { silent = true, desc = "Recent", noremap = true })

vim.keymap.set({ "n" }, "<leader>,", function()
    snacks.picker.buffers()
end, { silent = true, desc = "Buffers", noremap = true })

vim.keymap.set({ "n" }, "<leader>/", function()
    snacks.picker.grep()
end, { silent = true, desc = "Grep Files", noremap = true })
