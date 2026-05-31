-- ==== Intallation ===========================================================
--
local specs = require "specs"

vim.pack.add {
    specs["which-key.nvim"],
}

-- ==== Setup =================================================================
--
require("which-key").setup {
    preset = "helix",
    defaults = {},
    spec = {
        { "<leader>d", group = "Debug" },
        { "<leader>g", group = "Git" },
        { "<leader>gh", group = "Git Hunks" },
        { "[", group = "Previous" },
        { "]", group = "Next" },
        { "g", group = "Goto" },
        {
            "<leader>b",
            group = "Buffer",
            expand = function()
                return require("which-key.extras").expand.buf()
            end,
        },
        {
            "<leader>w",
            group = "Windows",
            proxy = "<c-w>",
            expand = function()
                return require("which-key.extras").expand.win()
            end,
        },
    },
}

-- ==== Setup Keybindings =====================================================
--
vim.keymap.set("n", "<leader>?", function()
    require("which-key").show { global = false }
end, { desc = "Buffer Local Keymaps (which-key)" })
