-- Intallation {{{
local specs = require "specs"

vim.pack.add {
    specs["conform.nvim"],
}
-- }}}

-- Setup {{{
require("conform").setup {
    default_format_opts = {
        timeout_ms = 3000,
        -- NOTE: not recommended to change.
        async = false,
        -- NOTE: not recommended to change.
        quiet = false,
        -- NOTE: not recommended to change.
        lsp_format = "fallback",
    },
    formatters_by_ft = {
        lua = { "stylua" },
        python = {
            -- To fix auto-fixable lint errors.
            "ruff_fix",
            -- To run the Ruff formatter.
            "ruff_format",
            -- To organize the imports.
            "ruff_organize_imports",
        },
        c = { "clang_format" },
        h = { "clang_format" },
        cpp = { "clang_format" },
        hpp = { "clang_format" },
        cmake = { "cmake-format" },
        toml = { "taplo" },
        json = { "prettier" },
        svelte = { "svelte" },
        javascript = { "oxfmt", "eslint", "prettier" },
        typescript = { "oxfmt", "eslint", "prettier" },
        javascriptreact = { "oxfmt", "eslint", "prettier" },
        typescriptreact = { "oxfmt", "eslint", "prettier" },
    },
    formatters = {
        clang_format = {
            command = "clang-format",
            prepend_args = {
                "--style={BasedOnStyle: LLVM, BreakBeforeBraces: Allman, IndentWidth: 4, IndentCaseLabels: true, ColumnLimit: 80, PointerAlignment: Left , AlignConsecutiveAssignments: true, AlignConsecutiveDeclarations: true, }",
            },
        },
        cmake_format = {
            command = "cmake-format",
            prepend_args = { "-i" },
        },
        prettier = {
            prepend_args = { "--tab-width", "4" },
        },
        injected = {
            options = {
                ignore_errors = true,
            },
        },
    },
}
-- }}}

-- Setup Keybindings {{{
vim.keymap.set({ "n", "v" }, "gf", function()
    require("conform").format {
        lsp_format = "fallback",
        timeout_ms = 3000,
    }
end, { desc = "LSP Format file or range (in visual mode)" })
-- }}}
