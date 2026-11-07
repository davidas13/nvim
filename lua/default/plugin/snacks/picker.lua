-- Setup ------------------------------------------------------------------- {{{
-- snacks.picker config: custom layout, explorer source, custom actions.
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
}
-- }}}
