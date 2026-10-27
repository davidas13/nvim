-- blink.cmp completion sources.
return {
    default = {
        "lsp",
        "path",
        "snippets",
        "supermaven",
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
        supermaven = {
            score_offset = 100,
            name = "supermaven",
            module = "blink-cmp-supermaven",
            async = true,
        },
    },
}
