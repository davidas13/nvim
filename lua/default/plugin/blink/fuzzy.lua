-- Setup ------------------------------------------------------------------- {{{
-- blink.cmp fuzzy matching options.
return {
    implementation = "prefer_rust_with_warning",
    sorts = {
        "score",
        "sort_text",
        "exact",
        "label",
    },
    use_proximity = true,
}
-- }}}
