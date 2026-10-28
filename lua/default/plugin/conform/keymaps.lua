-- Format keymap.
vim.keymap.set({ "n", "v" }, "gf", function()
    require("conform").format {
        lsp_format = "fallback",
        timeout_ms = 3000,
    }
end, { desc = "LSP Format file or range (in visual mode)" })
