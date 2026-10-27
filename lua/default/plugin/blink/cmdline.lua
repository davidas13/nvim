-- blink.cmp cmdline completion.
return {
    keymap = {
        ["<End>"] = { "hide", "fallback" },
    },
    completion = { ghost_text = { enabled = true } },
}
