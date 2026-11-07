-- Setup ------------------------------------------------------------------- {{{
-- Handlers that configure and enable each language server.
return {
    -- default handler, first entry with no key
    function(server, opts)
        vim.lsp.config(server, opts)
        vim.lsp.enable(server)
    end,
}
-- }}}
