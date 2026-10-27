-- Installation {{{
local specs = require "specs"

vim.pack.add {
    specs["tabby.nvim"],
}
-- }}}

-- Setup {{{
local theme = {
    fill = "TabLineFill",
    -- Also you can do this: fill = { fg='#f2e9de', bg='#907aa9', style='italic' }
    head = "TabLine",
    current_tab = "TabLineSel",
    tab = "TabLine",
    win = "TabLine",
    tail = "TabLine",
}

require("tabby").setup {
    line = function(line)
        return {
            line.tabs().foreach(function(tab)
                local hl = tab.is_current() and theme.current_tab or theme.tab
                return {
                    "",
                    tab.is_current() and "" or "󰆣",
                    tab.number(),
                    tab.name(),
                    line.sep(" ", hl, theme.fill),
                    hl = hl,
                    margin = " ",
                }
            end),
            line.spacer(),
            line.wins_in_tab(line.api.get_current_tab()).foreach(function(win)
                return {
                    line.sep(" ", theme.win, theme.fill),
                    win.is_current() and "" or "",
                    win.buf_name() .. " ",
                    hl = theme.win,
                    margin = " ",
                }
            end),
            hl = theme.fill,
        }
    end,
    -- option = {}, -- setup modules' option,
}

-- }}}

-- Setup Keybindings {{{
--
vim.keymap.set({ "n" }, "<leader>pa", function()
    vim.cmd [[:tabnew]]
end, { noremap = true, silent = true, desc = "New Tab" })

vim.keymap.set({ "n" }, "<leader>pr", function()
    vim.ui.input({ prompt = "Rename Tab: " }, function(input)
        vim.cmd("TabRename " .. input)
    end)
end, { noremap = true, silent = true, desc = "Rename Tab" })

vim.keymap.set({ "n" }, "<leader>pc", function()
    vim.cmd [[:tabclose]]
end, { noremap = true, silent = true, desc = "Close Tab" })

vim.keymap.set({ "n" }, "<leader>po", function()
    vim.cmd [[:tabonly]]
end, { noremap = true, silent = true, desc = "Close Tab" })

vim.keymap.set({ "n" }, "<leader>pn", function()
    vim.cmd [[:tabn]]
end, { noremap = true, silent = true, desc = "Next Tab" })

vim.keymap.set({ "n" }, "<leader>pp", function()
    vim.cmd [[:tabp]]
end, { noremap = true, silent = true, desc = "Previous Tab" })

vim.keymap.set({ "n" }, "<leader>pmp", function()
    vim.cmd [[:-tabmove]]
end, { noremap = true, silent = true, desc = "Move Tab to Previous Position" })

vim.keymap.set({ "n" }, "<leader>pmn", function()
    vim.cmd [[:+tabmove]]
end, { noremap = true, silent = true, desc = "Move Tab to Next Position" })

vim.keymap.set({ "n" }, "]g", function()
    vim.cmd [[:tabn]]
end, { noremap = true, silent = true, desc = "Next Tab" })

vim.keymap.set({ "n" }, "[g", function()
    vim.cmd [[:tabp]]
end, { noremap = true, silent = true, desc = "Previous Tab" })
-- }}}
