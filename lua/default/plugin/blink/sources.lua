-- blink.cmp completion sources.
return {
    default = {
        "lsp",
        "path",
        "snippets",
    },
    providers = {
        lsp = {
            score_offset = 9,
        },
        path = {
            score_offset = 8,
        },
        snippets = {
            score_offset = 7,
        },
        -- kept as a provider so it can be added to the default list later
        buffer = {
            score_offset = 6,
        },
    },
}
