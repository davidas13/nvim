-- Global keymaps for snacks pickers and explorer.
local snacks = require "snacks"

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
