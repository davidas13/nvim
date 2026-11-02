-- Launch configurations for C, C++, Rust, Zig, plus VSCode launch.json support.
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

dap.configurations.rust = {
    {
        name = "codelldb: Launch binary",
        type = "codelldb",
        request = "launch",
        program = function()
            return vim.fn.input("Executable path: ", vim.fn.getcwd() .. "/target/debug/", "file")
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        -- Rust toolchain formatters for the inspected values.
        sourceLanguages = { "rust" },
    },
}

dap.configurations.zig = {
    {
        name = "codelldb: Launch binary",
        type = "codelldb",
        request = "launch",
        program = function()
            return vim.fn.input("Executable path: ", vim.fn.getcwd() .. "/zig-out/bin/", "file")
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
    },
}

-- Entry points and prefixes are asked for, never guessed: node, bun, and deno
-- runtimes all start the same pwa-node server, so the prompt stays the path.
local js_configs = {
    {
        name = "pwa-node: Launch file",
        type = "pwa-node",
        request = "launch",
        program = "${file}",
        cwd = "${workspaceFolder}",
        sourceMaps = true,
        console = "integratedTerminal",
    },
    {
        name = "pwa-node: Launch entry (prompt)",
        type = "pwa-node",
        request = "launch",
        program = function()
            return vim.fn.input("Entry file: ", vim.fn.getcwd() .. "/", "file")
        end,
        cwd = "${workspaceFolder}",
        sourceMaps = true,
        console = "integratedTerminal",
    },
    {
        name = "pwa-chrome: Launch URL",
        type = "pwa-chrome",
        request = "launch",
        url = function()
            return vim.fn.input("URL: ", "http://localhost:", "file")
        end,
        webRoot = "${workspaceFolder}",
        sourceMaps = true,
    },
    {
        name = "pwa-chrome: Attach :9222",
        type = "pwa-chrome",
        request = "attach",
        port = 9222,
        webRoot = "${workspaceFolder}",
        sourceMaps = true,
    },
}

local function with_sourcemap_resolution(configs)
    for _, config in ipairs(configs) do
        -- TypeScript and Svelte emit maps next to the sources; node_modules
        -- resolution noise is excluded so breakpoints land on project files.
        config.resolveSourceMapLocations = { "${workspaceFolder}/**", "!**/node_modules/**" }
    end
    return configs
end

dap.configurations.javascript = vim.deepcopy(js_configs)
dap.configurations.javascriptreact = vim.deepcopy(js_configs)
dap.configurations.typescript =
    with_sourcemap_resolution(vim.deepcopy(js_configs))
dap.configurations.typescriptreact =
    with_sourcemap_resolution(vim.deepcopy(js_configs))
dap.configurations.svelte = with_sourcemap_resolution(vim.deepcopy(js_configs))
