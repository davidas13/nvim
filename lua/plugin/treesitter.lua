-- ==== Intallation ===========================================================
--
vim.pack.add {
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "master" },
}

-- ==== Setup =================================================================
--
require "nvim-treesitter.query_predicates"

require("nvim-treesitter.configs").setup {
    auto_install = true,
    highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
        use_languagetree = true,
    },
    indent = { enable = true },
    ensure_installed = {
        "bash",
        "c",
        "cpp",
        "diff",
        "html",
        "javascript",
        "jsdoc",
        "json",
        "jsonc",
        "lua",
        "luadoc",
        "markdown",
        "markdown_inline",
        "printf",
        "python",
        "query",
        "regex",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "xml",
        "yaml",
        "ninja",
        "rst",
        "rust",
        "zig",
    },
}
