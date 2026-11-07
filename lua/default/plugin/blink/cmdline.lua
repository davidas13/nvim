-- Setup ------------------------------------------------------------------- {{{
-- blink.cmp cmdline completion.
return {
    keymap = {
        ["<End>"] = { "hide", "fallback" },
        -- Accept the highlighted completion item instead of running the command.
        -- A second <CR> runs the command once the popup is gone.
        ["<CR>"] = { "accept", "fallback" },
    },
    completion = { ghost_text = { enabled = true } },
}
-- }}}
