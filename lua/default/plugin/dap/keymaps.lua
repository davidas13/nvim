-- Debug keymaps.
local dap = require "dap"

vim.keymap.set("n", "<leader>DB", function()
    dap.set_breakpoint(vim.fn.input "Breakpoint Condition: ")
end, { desc = "Breakpoint Condition" })

vim.keymap.set("n", "<leader>Dt", function()
    dap.toggle_breakpoint()
end, { desc = "Toggle Breakpoint" })

vim.keymap.set("n", "<leader>Dc", function()
    dap.continue()
end, { desc = "Run/Continue" })

vim.keymap.set("n", "<leader>Da", function()
    dap.continue {
        before = function(config)
            local args = type(config.args) == "function" and (config.args() or {}) or config.args or {}
            config = vim.deepcopy(config)
            ---@cast args string[]
            config.args = function()
                local new_args = vim.fn.input("Run with args: ", table.concat(args, " "))
                return vim.split(vim.fn.expand(new_args), " ")
            end
            return config
        end,
    }
end, { desc = "Run/Continue with Args" })

vim.keymap.set("n", "<leader>DC", function()
    dap.run_to_cursor()
end, { desc = "Run to Cursor" })

vim.keymap.set("n", "<leader>Dg", function()
    dap.goto_()
end, { desc = "Go to line (No execute)" })

vim.keymap.set("n", "<leader>DT", function()
    dap.terminate()
end, { desc = "Terminate" })

vim.keymap.set("n", "<leader>Di", function()
    dap.step_into()
end, { desc = "Step Into" })

vim.keymap.set("n", "<leader>Do", function()
    dap.step_out()
end, { desc = "Step Out" })

vim.keymap.set("n", "<leader>DO", function()
    dap.step_over()
end, { desc = "Step Over" })

vim.keymap.set("n", "<leader>Dl", function()
    dap.run_last()
end, { desc = "Run Last" })

vim.keymap.set("n", "<leader>Dp", function()
    dap.pause()
end, { desc = "Pause" })

vim.keymap.set("n", "<leader>Dr", function()
    dap.repl.toggle()
end, { desc = "Toggle REPL" })

vim.keymap.set("n", "<leader>Ds", function()
    dap.session()
end, { desc = "Session" })

vim.keymap.set("n", "<leader>Dx", function()
    dap.disconnect()
end, { desc = "Session" })

vim.keymap.set("n", "<leader>Dv", function()
    vim.cmd [[DapViewOpen]]
end, { desc = "Open DAP View" })
