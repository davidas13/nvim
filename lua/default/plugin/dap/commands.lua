-- Debug workflow commands. The :Dap* commands cover the session actions; this
-- file adds only what they do not provide.
local dap = require "dap"
local vscode = require "dap.ext.vscode"

vim.api.nvim_create_user_command("DebugBreakpoint", function()
    dap.set_breakpoint(vim.fn.input "Breakpoint condition: ")
end, { desc = "Breakpoint with condition" })

vim.api.nvim_create_user_command("DebugLogPoint", function()
    dap.set_breakpoint(nil, nil, vim.fn.input "Log point message: ")
end, { desc = "Log point with message" })

vim.api.nvim_create_user_command("DebugView", function()
    vim.cmd "DapViewToggle"
end, { desc = "Toggle debug view" })

vim.api.nvim_create_user_command("DebugReloadJson", function()
    local ok, err = pcall(vscode.load_launchjs)
    if not ok then
        vim.notify("DebugReloadJson: " .. err, vim.log.levels.ERROR)
    end
end, { desc = "Reload .vscode/launch.json" })
