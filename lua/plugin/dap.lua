-- ==== Intallation ===========================================================
--
vim.pack.add {
    { src = "https://github.com/mason-org/mason.nvim" },
    { src = "https://github.com/rcarriga/nvim-dap-ui" },
    { src = "https://github.com/nvim-neotest/nvim-nio" },
    { src = "https://github.com/jay-babu/mason-nvim-dap.nvim" },
    { src = "https://github.com/theHamsta/nvim-dap-virtual-text" },
    { src = "https://github.com/igorlfs/nvim-dap-view" },

    -- Main plugin.
    { src = "https://github.com/mfussenegger/nvim-dap" },
}

-- ==== Setup =================================================================
--
local dap_mason = require "mason-nvim-dap"
local dap = require "dap"
local dap_ui = require "dapui"
local dap_virtual_text = require "nvim-dap-virtual-text"
local mason_registry = require "mason-registry"

local function find_codelldb()
    local codelldb_pkg = mason_registry.get_package "codelldb"
    local install_path = codelldb_pkg:get_install_path()

    local adapter = install_path .. "/extension/adapter/codelldb"

    return adapter
end

dap_mason.setup {
    ensure_installed = { "codelldb", "bash", "python" },
    automatic_installation = true,
    handlers = {},
}
dap_ui.setup()
dap_virtual_text.setup()

vim.fn.sign_define("DapBreakpoint", { text = "🐞" })
vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

dap.listeners.before.attach.dapui_config = function()
    dap_ui.open()
end

dap.listeners.before.launch.dapui_config = function()
    dap_ui.open()
end

dap.listeners.before.event_terminated.dapui_config = function()
    dap_ui.close()
end

dap.listeners.before.event_exited.dapui_config = function()
    dap_ui.close()
end

-- setup dap config by VsCode launch.json file
local vscode = require "dap.ext.vscode"
local json = require "plenary.json"

vscode.json_decode = function(str)
    return vim.json.decode(json.json_strip_comments(str))
end

-- ==== Adapter Configuration =================================================

dap.adapters.codelldb = {
    type = "server",
    port = "${port}",
    executable = {
        command = vim.fn.stdpath "data" .. "/mason/bin/codelldb",
        args = { "--port", "${port}" },
    },
}

-- ==== Language Configuration ================================================

dap.configurations.cpp = {
    {
        name = "Launch file",
        type = "codelldb",
        request = "launch",
        program = function()
            return vim.fn.input("Executable path: ", vim.fn.getcwd() .. "/", "file")
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        MIMode = "lldb",
    },
}

dap.configurations.c = dap.configurations.cpp

-- ==== Setup Keybindings =====================================================
--
vim.keymap.set("n", "<leader>dB", function()
    dap.set_breakpoint(vim.fn.input "Breakpoint Condition: ")
end, { desc = "Breakpoint Condition" })

vim.keymap.set("n", "<leader>dt", function()
    dap.toggle_breakpoint()
end, { desc = "Toggle Breakpoint" })

vim.keymap.set("n", "<leader>dc", function()
    dap.continue()
end, { desc = "Run/Continue" })

vim.keymap.set("n", "<leader>dC", function()
    dap.run_to_cursor()
end, { desc = "Run to Cursor" })

vim.keymap.set("n", "<leader>dT", function()
    dap.terminate()
end, { desc = "Terminate" })

vim.keymap.set("n", "<leader>di", function()
    dap.step_into()
end, { desc = "Step Into" })

vim.keymap.set("n", "<leader>do", function()
    dap.step_out()
end, { desc = "Step Out" })

vim.keymap.set("n", "<leader>dO", function()
    dap.step_over()
end, { desc = "Step Over" })
