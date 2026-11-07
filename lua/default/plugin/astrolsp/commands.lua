-- Setup ------------------------------------------------------------------- {{{
-- Buffer local user commands added when a language server attaches.
return {
    Format = {
        function()
            require("conform").format(
                ---@type conform.FormatOpts
                {
                    lsp_format = "fallback",
                    timeout_ms = 3000,
                }
            )
        end,
        -- condition can be a client capability string or `fun(client, bufnr): boolean`
        cond = "textDocument/formatting",
        desc = "Format file with LSP",
    },
}
-- }}}
