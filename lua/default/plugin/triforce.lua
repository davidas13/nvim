-- ==== Intallation ===========================================================
--
local specs = require "specs"

vim.pack.add {
    specs["which-key.nvim"],
    specs["volt"],
    specs["triforce.nvim"],
}

-- ==== Setup =================================================================
--
local triforce = require "triforce"

triforce.setup()

-- ==== Setup Keybindings =====================================================
--
require("which-key").add {
    { "<leader>\"", mode = "n", group = "Triforce" },
}

vim.keymap.set(
    "n",
    "<leader>\"p",
    triforce.show_profile,
    { noremap = true, silent = true, desc = "Open Triforce Profile" }
)

vim.keymap.set("n", "<leader>\"s", triforce.get_stats, { noremap = true, silent = true, desc = "Get Triforce Stats" })

vim.keymap.set(
    "n",
    "<leader>\"r",
    triforce.reset_stats,
    { noremap = true, silent = true, desc = "Reset Triforce Stats" }
)

vim.keymap.set("n", "<leader>\"S", triforce.save_stats, { noremap = true, silent = true, desc = "Save Triforce Stats" })

vim.keymap.set(
    "n",
    "<leader>\"d",
    triforce.debug_languages,
    { noremap = true, silent = true, desc = "Debug Triforce Languages" }
)
