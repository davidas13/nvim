local specs = require "specs"

vim.pack.add {
    specs["plenary.nvim"],
    specs["mason.nvim"],
    specs["nvim-nio"],
    specs["mason-nvim-dap.nvim"],
    specs["nvim-dap-virtual-text"],
    specs["nvim-dap"],
}

local dap_mason = require "mason-nvim-dap"
local dap_virtual_text = require "nvim-dap-virtual-text"

dap_mason.setup {
    ensure_installed = { "cppdbg", "codelldb", "bash", "python" },
    automatic_installation = true,
    handlers = {},
}

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

require "default.plugin.dap.adapters"
require "default.plugin.dap.configurations"
require "default.plugin.dap.keymaps"
