-- ==== Intallation ===========================================================
--
vim.pack.add {
    -- Main Plugin.
    { src = "https://github.com/stevearc/conform.nvim", version = "v9.0.0" },
}

-- ==== Setup =================================================================
--
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
        cpp = { "clang_format" },
        hpp = { "clang_format" },
        cmake = { "cmake-format" },
        toml = { "taplo" },
        json = { "prettier" },
        svelte = { "svelte" },
    },
    formatters = {
        ["cmake-format"] = {
            command = "cmake-format",
            prepend_args = { "-i" },
        },
        injected = {
            options = {
                ignore_errors = true,
            },
        },
    },
}

-- ==== Setup Keybindings =====================================================
--
vim.keymap.set({ "n", "v" }, "gf", function()
    require("conform").format {
        lsp_format = "fallback",
        timeout_ms = 3000,
    }
end, { desc = "LSP Format file or range (in visual mode)" })
