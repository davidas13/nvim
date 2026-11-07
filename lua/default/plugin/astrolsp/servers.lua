-- Setup ------------------------------------------------------------------- {{{
-- Language servers to set up, including ones not installed with Mason.
return {
    "ast_grep",
    "autotools_ls",

    -- Lua
    "lua_ls",

    -- Json
    "jsonls",
    "biome",

    -- Toml
    "taplo",

    -- Bash
    "bashls",

    -- Python
    "ruff",
    "basedpyright",

    -- C/C++
    "neocmake",
    "cmakels",
    "clangd",

    -- Typescript/JavaScript
    "ts_ls",
    "svelte",

    -- Rust
    "rust_analyzer",

    -- Zig
    "zls",

    -- Godot
    "gdscript",

    "sonarlint",

    "docker-compose-langserver",
}
-- }}}
