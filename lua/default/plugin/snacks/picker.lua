-- Setup ------------------------------------------------------------------- {{{
-- snacks.picker config: custom layout, explorer source, custom actions.

local picker_actions = require "snacks.picker.actions"
local original_jump = picker_actions.jump

local function in_diff_tab()
    local tab = vim.api.nvim_get_current_tabpage()
    return vim.fn.gettabvar(
        vim.api.nvim_tabpage_get_number(tab),
        "diffexplorer_title",
        ""
    ) ~= ""
end

local function guarded_jump(picker, item, action)
    if not in_diff_tab() then
        return original_jump(picker, item, action)
    end
    local items = picker:selected { fallback = true }
    if #items == 0 then
        return
    end
    local selected = items[1]
    if not selected.file or selected.file == "" then
        return
    end
    picker:close()
    vim.cmd(("tabedit %s"):format(vim.fn.fnameescape(selected.file)))
    local pos = selected.pos
    if pos and pos[1] > 0 then
        vim.api.nvim_win_set_cursor(0, { pos[1], pos[2] or 0 })
    end
end

-- Opens ": <path>" with the cursor right after ":" (via <C-b>), so an Ex
-- command can be typed in front of the path.
local function start_cmdline(path)
    local to_start = vim.api.nvim_replace_termcodes("<C-b>", true, false, true)
    vim.api.nvim_feedkeys(
        ": " .. vim.fn.fnameescape(path) .. to_start,
        "n",
        false
    )
end

return {
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
                    {
                        win = "preview",
                        title = "{preview}",
                        width = 0.6,
                        border = "rounded",
                    },
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
            keys = {
                ["<c-l>"] = "loclist",
                ["<c-x>"] = "start_cmd",
                ["<c-y>"] = "start_cmd_abs",
            },
        },
        input = {
            keys = {
                ["<c-l>"] = { "loclist", mode = { "i", "n" } },
                ["<c-x>"] = { "start_cmd", mode = { "i", "n" } },
                ["<c-y>"] = { "start_cmd_abs", mode = { "i", "n" } },
            },
        },
    },
    actions = {
        jump = guarded_jump,
        start_cmd = {
            action = function(picker, item)
                if not item or not item.file then
                    return
                end
                picker:close()
                -- ":." resolves against the main window cwd after the picker
                -- closes, the same base the Ex command uses
                start_cmdline(vim.fn.fnamemodify(item.file, ":."))
            end,
        },
        start_cmd_abs = {
            action = function(picker, item)
                if not item or not item.file then
                    return
                end
                picker:close()
                start_cmdline(item.file)
            end,
        },
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
            exclude = {
                "*.pyc",
                "*.pyo",
                "*.pyd",
                "*.pyw",
                "*.bak",
                "*.orig",
                ".git",
                ".hg",
                ".svn",
                ".tox",
                ".venv",
                "cmake-build-*",
                "*.egg-info",
                "__pycache__",
                ".pytest_cache",
                ".mypy_cache",
                ".ruff_cache",
                ".dmypy.json",
                ".pyre",
                ".DS_Store",
            },
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
            -- These actions follow Rico Berger's snacks.nvim explorer post.
            -- source: https://ricoberger.de/blog/posts/neovim-extend-snacks-nvim-explorer/
            -- See THIRD_PARTY_NOTICES.md for the notice.
            actions = {
                copy_file_path = {
                    action = function(_, item)
                        if not item then
                            return
                        end

                        local vals = {
                            ["BASENAME"] = vim.fn.fnamemodify(
                                item.file,
                                ":t:r"
                            ),
                            ["EXTENSION"] = vim.fn.fnamemodify(
                                item.file,
                                ":t:e"
                            ),
                            ["FILENAME"] = vim.fn.fnamemodify(item.file, ":t"),
                            ["PATH"] = item.file,
                            ["PATH (CWD)"] = vim.fn.fnamemodify(
                                item.file,
                                ":."
                            ),
                            ["PATH (HOME)"] = vim.fn.fnamemodify(
                                item.file,
                                ":~"
                            ),
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
                                return ("%s: %s"):format(
                                    list_item,
                                    vals[list_item]
                                )
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
                            Snacks.notify.info(
                                "Diffing "
                                    .. sel[1].file
                                    .. " against "
                                    .. sel[2].file
                            )
                            return
                        end

                        Snacks.notify.info "Select two entries for the diff"
                    end,
                },
            },
        },
    },
}
-- }}}
