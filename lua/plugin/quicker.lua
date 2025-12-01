-- ==== Intallation ===========================================================
--
vim.pack.add {
    { src = "https://github.com/stevearc/quicker.nvim" },
}

-- ==== Setup =================================================================
--
require("quicker").setup()
vim.keymap.set("n", "<leader>lq", function()
    require("quicker").toggle()
end, {
    desc = "Toggle quickfix",
})

vim.keymap.set("n", "<leader>ll", function()
    require("quicker").toggle { loclist = true }
end, {
    desc = "Toggle loclist",
})
