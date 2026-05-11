-- Start: Installation
--
vim.pack.add {
    { src = "https://github.com/thesimonho/kanagawa-paper.nvim", version = "master" },

    -- Main plugin.
    { src = "https://github.com/rebelot/kanagawa.nvim", version = "master" },
}
--
-- End

-- Start: Setup
--
require("kanagawa").setup {
    transparent = true,
    theme = "wave",
    colors = {
        theme = {
            all = {
                ui = {
                    bg_gutter = "none",
                },
            },
        },
    },
}
--
-- End

-- Start: Implementation
-- vim.cmd [[colorscheme kanagawa]]
vim.cmd [[colorscheme kanagawa-paper]]
--
-- End
