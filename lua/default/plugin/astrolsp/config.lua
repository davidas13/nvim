-- Setup ------------------------------------------------------------------- {{{
-- Per server configuration overrides (`:h lspconfig-setup`).
return {
    -- Lua LSP
    lua_ls = {
        settings = {
            Lua = {
                enable = true,
                quote_style = "double",
            },
            signatureHelp = { enable = true },
            hint = { enable = true, arrayIndex = "Disable" },
        },
    },

    -- Python LSP
    basedpyright = {
        settings = {
            basedpyright = {
                analysis = {
                    autoSearchPaths = true,
                    useLibraryCodeForTypes = true,
                    diagnosticMode = "workspace", -- "off" | "openFilesOnly" | "workspace"
                    typeCheckingMode = "standard", -- "off" | "basic" | "standard" | "strict" | "recommended" | "all"
                    inlayHints = {
                        callArgumentNames = true,
                        functionReturnTypes = true,
                    },
                    fileEnumerationTimeout = 300,
                    reportUndefinedVariable = true,
                    reportUnnecessaryTypeIgnoreComment = true,
                },
            },
        },
    },

    -- Python LSP
    ruff = {
        settings = {
            logLevel = "debug",
            lint = {
                preview = true,
                enable = true,
            },
            format = {
                preview = true,
                enable = true,
            },
        },
    },
}
-- }}}
