-- ==== intallation ===========================================================
--
vim.pack.add {
    -- main plugin.
    { src = "https://github.com/shellRaining/hlchunk.nvim" },
}

-- ==== setup =================================================================
--
require("hlchunk").setup {
    chunk = {
        enable = true,
        priority = 15,
        duration = 0,
        delay = 0,
        -- style = "#C99B54",
        style = "#EA6962"
    },
    line_num = {
        enable = true,
        -- style = "#7CAEA3",
        style = "#C99B54",
        priority = 10,
    },
    indent = {
        enable = true,
    },
}
