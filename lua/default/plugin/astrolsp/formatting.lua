-- Formatting control for language servers.
return {
    format_on_save = {
        -- enable or disable format on save globally
        enabled = false,
        -- enable format on save for specified filetypes only
        allow_filetypes = {
            "lua",
            "py",
            "cpp",
            "c",
            "zig",
            "rs",
            "ts",
            "js",
            "toml",
        },
    },
    -- default format timeout
    timeout_ms = 1000,
}
