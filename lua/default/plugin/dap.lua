-- Intallation {{{
local specs = require "specs"

vim.pack.add {
    specs["plenary.nvim"],
    specs["mason.nvim"],
    specs["nvim-nio"],
    specs["mason-nvim-dap.nvim"],
    specs["nvim-dap-virtual-text"],
    specs["nvim-dap-view"],
    specs["nvim-dap"],
}
-- }}}

-- Setup {{{
local dap = require "dap"
local dap_view = require "dap-view"
local dap_mason = require "mason-nvim-dap"
local dap_virtual_text = require "nvim-dap-virtual-text"

dap_mason.setup {
    ensure_installed = { "cppdbg", "codelldb", "bash", "python" },
    automatic_installation = true,
    handlers = {},
}
-- dap_ui.setup()
dap_virtual_text.setup()

vim.api.nvim_set_hl(0, "DapBreakpoint", { ctermbg = 0, fg = "#993939", bg = "#31353f" })
vim.api.nvim_set_hl(0, "DapLogPoint", { ctermbg = 0, fg = "#61afef", bg = "#31353f" })
vim.api.nvim_set_hl(0, "DapStopped", { ctermbg = 0, fg = "#98c379", bg = "#31353f" })
vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

vim.fn.sign_define(
    "DapBreakpoint",
    { text = "", texthl = "DapBreakpoint", linehl = "DapBreakpoint", numhl = "DapBreakpoint" }
)
vim.fn.sign_define(
    "DapBreakpointCondition",
    { text = "", texthl = "DapBreakpoint", linehl = "DapBreakpoint", numhl = "DapBreakpoint" }
)
vim.fn.sign_define(
    "DapBreakpointRejected",
    { text = "", texthl = "DapBreakpoint", linehl = "DapBreakpoint", numhl = "DapBreakpoint" }
)
vim.fn.sign_define(
    "DapLogPoint",
    { text = "", texthl = "DapLogPoint", linehl = "DapLogPoint", numhl = "DapLogPoint" }
)
vim.fn.sign_define("DapStopped", { text = "", texthl = "DapStopped", linehl = "DapStopped", numhl = "DapStopped" })

dap.listeners.before.attach.dapui_config = function()
    dap_view.open()
end

dap.listeners.before.launch.dapui_config = function()
    dap_view.open()
end

dap.listeners.before.event_terminated.dapui_config = function()
    dap_view.close()
end

dap.listeners.before.event_exited.dapui_config = function()
    dap_view.close()
end

-- setup dap config by VsCode launch.json file
local vscode = require "dap.ext.vscode"
local json = require "plenary.json"

vscode.json_decode = function(str)
    return vim.json.decode(json.json_strip_comments(str))
end

-- }}}

-- Adapter Configuration {{{

dap.adapters.codelldb = {
    type = "server",
    port = "${port}",
    executable = {
        command = vim.fn.stdpath "data" .. "/mason/bin/codelldb",
        args = { "--port", "${port}" },
    },
}

dap.adapters.cppdbg = {
    id = "cppdbg",
    type = "executable",
    command = vim.fn.stdpath "data" .. "/mason/bin/cppdbg",
}

-- }}}

-- Language Configuration {{{

dap.configurations.cpp = {
    -- https://codeberg.org/mfussenegger/nvim-dap/wiki/C-C---Rust-(gdb-via--vscode-cpptools)
    {
        name = "cppdbg: Launch file",
        type = "cppdbg",
        request = "launch",
        program = function()
            return vim.fn.input("Executable path: ", vim.fn.getcwd() .. "/", "file")
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = true,
        exitAfterTaskReturns = false,
    },
    {
        name = "cppgdbg: Attach to gdbserver :1234",
        type = "cppdbg",
        request = "launch",
        MIMode = "gdb",
        miDebuggerServerAddress = "localhost:1234",
        miDebuggerPath = "/usr/bin/gdb",
        cwd = "${workspaceFolder}",
        program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
        end,
    },
    -- https://codeberg.org/mfussenegger/nvim-dap/wiki/C-C---Rust-%28via--codelldb%29
    {
        name = "codelldbc: Launch file",
        type = "codelldb",
        request = "launch",
        program = function()
            return vim.fn.input("Executable path: ", vim.fn.getcwd() .. "/", "file")
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        exitAfterTaskReturns = false,
    },
}

dap.configurations.c = dap.configurations.cpp
dap.configurations.rust = dap.configurations.cpp

-- }}}

-- Setup Keybindings {{{
--
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
-- }}}
