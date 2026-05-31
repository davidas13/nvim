-- ==== Intallation ===========================================================
--
local specs = require "specs"

vim.pack.add {
    specs["nui.nvim"],
    specs["nvim-notify"],
    specs["noice.nvim"],
}

-- ==== Setup =================================================================
--
require("noice").setup {
    messages = {
        enabled = true,
    },
    routes = {
        {
            view = "notify", -- Forces message output into the snacks/notify window
            filter = { event = "msg_show" },
        },
    },
    cmdline = {
        view = "cmdline",
    },
    views = {
        cmdline_popup = {
            position = {
                row = 5,
                col = "50%",
            },
            size = {
                width = 60,
                height = "auto",
            },
        },
        popupmenu = {
            relative = "editor",
            position = {
                row = 8,
                col = "50%",
            },
            size = {
                width = 60,
                height = 10,
            },
            border = {
                style = "rounded",
                padding = { 0, 1 },
            },
            win_options = {
                winhighlight = { Normal = "Normal", FloatBorder = "DiagnosticInfo" },
            },
        },
    },
}
