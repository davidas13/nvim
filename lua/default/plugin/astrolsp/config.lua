-- Setup ------------------------------------------------------------------- {{{
-- Per server configuration overrides (`:h lspconfig-setup`).
-- A server attaches only when Neovim finds a workspace root.
local vcs_markers = { ".git", ".hg", ".jj" }
local web_markers = vim.list_extend(vim.deepcopy(vcs_markers), {
    "package-lock.json",
    "yarn.lock",
    "pnpm-lock.yaml",
    "bun.lockb",
    "bun.lock",
    "deno.json",
    "deno.jsonc",
    "deno.lock",
})
local servers = require "default.plugin.astrolsp.servers"

-- ast-grep needs sgconfig, so a VCS root would start it without a project.
local config_marker_servers = { ast_grep = true }

-- Some configs fall back to cwd, so resolve the root from markers instead.
local function project_root(markers)
    return function(bufnr, on_dir)
        on_dir(vim.fs.root(bufnr, markers))
    end
end

local config = {
    ["*"] = {
        workspace_required = true,
    },

    -- Lua LSP
    lua_ls = {
        settings = {
            -- lua_ls reads these under settings.Lua, root-level keys are ignored.
            Lua = {
                signatureHelp = { enable = true },
                hint = { enable = true, arrayIndex = "Disable" },
            },
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

    -- These configs resolve their own root and fall back to cwd or git only.
    ts_ls = {
        root_dir = project_root(web_markers),
    },

    svelte = {
        root_dir = project_root(web_markers),
    },

    rust_analyzer = {
        root_dir = project_root(vim.list_extend(vim.deepcopy(vcs_markers), {
            "Cargo.toml",
            "rust-project.json",
        })),
    },

    -- Python LSP
    ruff = {
        -- ruff reads server settings from init_options, not workspace settings.
        init_options = {
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
    },
}

-- Configs with a root_dir function ignore root_markers and resolve their own root.
for _, server in ipairs(servers) do
    local resolved = vim.lsp.config[server]
    if resolved then
        local entry = vim.tbl_deep_extend("force", config[server] or {}, {
            workspace_required = true,
        })
        if
            type(resolved.root_dir) ~= "function"
            and not config_marker_servers[server]
        then
            local markers = vim.deepcopy(resolved.root_markers or vcs_markers)
            for _, marker in ipairs(vcs_markers) do
                if not vim.list_contains(markers, marker) then
                    table.insert(markers, marker)
                end
            end
            entry.root_markers = markers
        end
        config[server] = entry
    end
end

return config
-- }}}
