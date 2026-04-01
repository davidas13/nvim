-- ==== Intallation ===========================================================
--
vim.pack.add {
    -- Main plugin.
    { src = "https://github.com/supermaven-inc/supermaven-nvim" },
    { src = "https://github.com/huijiro/blink-cmp-supermaven" },
}

-- ==== Setup =================================================================
--
local supermaven = require "supermaven-nvim"

supermaven.setup {
    log_level = "off",
    -- disables inline completion for use with cmp.
    disable_inline_completion = true,
    -- disables built in keymaps for more manual control.
    disable_keymaps = true,
}
