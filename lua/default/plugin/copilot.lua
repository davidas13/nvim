-- ==== Intallation ===========================================================
--
local specs = require "specs"

vim.pack.add {
    specs["copilot-lsp"],
    specs["copilot.lua"],
}

-- ==== Setup =================================================================
--
require("copilot").setup {
    copilot_model = "gpt-5-mini",
    nes = {
        enabled = false,
        keymap = {
            accept_and_goto = "<leader>ap",
            accept = false,
            dismiss = "<Esc>",
        },
    },
    suggestion = { enabled = false },
    panel = { enabled = false, auto_refresh = true },
    filetypes = {
        markdown = true,
        help = true,
    },
}

-- vim.api.nvim_create_autocmd("InsertEnter", {
--     callback = function()
--         vim.lsp.start {
--             name = "copilot",
--             cmd = { "Copi" },
--             root_dir = vim.loop.cwd(),
--         }
--     end,
-- })
