-- ==== Intallation ===========================================================
vim.pack.add {
    {
        src = "https://github.com/sainnhe/gruvbox-material",
        version = "master",
    },
    {
        src = "https://github.com/f4z3r/gruvbox-material.nvim",
        version = "master",
    },

    -- Main plugin.
    {
        src = "https://github.com/morhetz/gruvbox",
        version = "master",
    },
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
