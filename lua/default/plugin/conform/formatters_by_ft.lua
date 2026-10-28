-- Formatters per filetype.
return {
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
}
