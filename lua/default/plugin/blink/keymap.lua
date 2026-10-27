-- blink.cmp key mappings.
return {
    preset = "default",
    ["<c-k>"] = { "show", "show_documentation", "hide_documentation" },
    ["<up>"] = { "select_prev", "fallback" },
    ["<down>"] = { "select_next", "fallback" },
    ["<c-n>"] = { "select_next", "show" },
    ["<c-p>"] = { "select_prev", "show" },
    ["<c-u>"] = { "scroll_documentation_up", "fallback" },
    ["<c-d>"] = { "scroll_documentation_down", "fallback" },
    ["<c-e>"] = { "hide", "fallback" },
    ["<cr>"] = { "accept", "fallback" },
}
