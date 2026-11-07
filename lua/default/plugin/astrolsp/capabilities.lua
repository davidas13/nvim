-- Setup ------------------------------------------------------------------- {{{
-- Default client capabilities merged into every language server.
return require("blink.cmp").get_lsp_capabilities {
    textDocument = {
        foldingRange = {
            dynamicRegistration = true,
        },
    },
}
-- }}}
