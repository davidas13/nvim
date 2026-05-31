-- ==== Intallation ===========================================================
local specs = require "specs"

vim.pack.add {
    specs["gruvbox-material"],
    specs["gruvbox-material.nvim"],
    specs["gruvbox"],
}
-- ==== Setup =================================================================
-- vim.g.gruvbox_material_enable_italic = false
-- vim.g.gruvbox_material_background = "medium"
-- vim.cmd [[colorscheme gruvbox-material]]
-- vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#32302F" })
-- vim.api.nvim_set_hl(0, "FloatBorder", { bg = "#32302F", fg = "#918374" })

-- vim.cmd [[colorscheme gruvbox]]

require("gruvbox-material").setup {
    background = {
        transparent = true,
    },
}
