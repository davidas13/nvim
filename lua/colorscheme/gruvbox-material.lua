-- ==== Intallation ===========================================================
vim.pack.add {
    {
        src = "https://github.com/sainnhe/gruvbox-material",
        version = "master",
    },
}
-- ==== Setup =================================================================
vim.g.gruvbox_material_enable_italic = true
vim.g.gruvbox_material_background = "medium"

vim.cmd [[colorscheme gruvbox-material]]
