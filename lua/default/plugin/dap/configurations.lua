-- Launch configurations for C, C++, and Rust, plus VSCode launch.json support.
local dap = require "dap"
local vscode = require "dap.ext.vscode"
local json = require "plenary.json"

vscode.json_decode = function(str)
    return vim.json.decode(json.json_strip_comments(str))
end

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
