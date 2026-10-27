-- Buffer local auto commands added when a language server attaches.
return {
    -- first key is the `augroup` (:h augroup)
    lsp_codelens_refresh = {
        cond = "textDocument/codeLens",
        {
            event = { "TextChanged", "InsertLeave", "BufEnter" },
            desc = "Refresh codelens (buffer)",
            callback = function(args)
                vim.lsp.codelens.refresh { bufnr = args.buf }
            end,
        },
    },
    lsp_document_highlight = {
        -- condition can be a client capability string or `fun(client, bufnr): boolean`
        cond = "textDocument/documentHighlight",
        {
            event = { "CursorHold", "CursorHoldI" },
            desc = "Document Highlighting",
            callback = function()
                vim.lsp.buf.document_highlight()
            end,
        },
        {
            event = { "CursorMoved", "CursorMovedI", "BufLeave" },
            desc = "Document Highlighting Clear",
            callback = function()
                vim.lsp.buf.clear_references()
            end,
        },
    },
}
