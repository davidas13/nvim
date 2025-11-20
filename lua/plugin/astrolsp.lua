-- ==== Installation ==========================================================
--
vim.pack.add {
    { src = "https://github.com/saghen/blink.cmp" },
    { src = "https://github.com/stevearc/conform.nvim" },
    { src = "https://github.com/neovim/nvim-lspconfig" },

    { src = "https://github.com/folke/snacks.nvim" },

    -- Main Plugin.
    { src = "https://github.com/neovim/nvim-lspconfig", version = "v2.5.0" },
    { src = "https://github.com/AstroNvim/astrolsp", version = "v3.2.1" },
}

-- ==== Setup =================================================================
--
local astrolsp = require "astrolsp"

-- Disable default lsp keybindings.
local keys = { "gra", "gri", "grn", "grr", "grt", "grO" }

for _, key in ipairs(keys) do
    pcall(vim.keymap.del, "n", key)
end

astrolsp.setup {
    -- ---- Features ----------------------------------------------------------
    -- Configuration table of features provided by AstroLSP
    features = {
        codelens = true, -- enable/disable codelens refresh on start
        inlay_hints = false, -- enable/disable inlay hints on start
        semantic_tokens = true, -- enable/disable semantic token highlighting
    },

    -- ---- Auto Commands -----------------------------------------------------
    -- Configure buffer local auto commands to add when attaching a language server
    autocmds = {
        -- first key is the `augroup` (:h augroup)
        lsp_codelens_refresh = {
            cond = "textDocument/codeLens",
            {
                event = { "TextChanged", "InsertLeave", "BufEnter" },
                desc = "Refresh codelens (buffer)",
                callback = function(args)
                    vim.lsp.codelens.refresh { bufnr = args.buf }
                end,
            },
        },

        -- lsp_auto_format = {
        --     cond = "textDocument/formatting",
        --     {
        --         event = "BufWritePre",
        --         callback = function()
        --             -- vim.lsp.buf.format()
        --
        --             require("conform").format(
        --                 ---@type conform.FormatOpts
        --                 {
        --                     lsp_format = "fallback",
        --                     timeout_ms = 3000,
        --                 }
        --             )
        --         end,
        --     },
        -- },

        lsp_document_highlight = {
            -- condition to create/delete auto command group
            -- can either be a string of a client capability or a function of `fun(client, bufnr): boolean`
            -- condition will be resolved for each client on each execution and if it ever fails for all clients,
            -- the auto commands will be deleted for that buffer
            cond = "textDocument/documentHighlight",
            -- list of auto commands to set
            {
                -- events to trigger
                event = { "CursorHold", "CursorHoldI" },
                -- the rest of the autocmd options (:h nvim_create_autocmd)
                desc = "Document Highlighting",
                callback = function()
                    vim.lsp.buf.document_highlight()
                end,
            },
            {
                event = { "CursorMoved", "CursorMovedI", "BufLeave" },
                desc = "Document Highlighting Clear",
                callback = function()
                    vim.lsp.buf.clear_references()
                end,
            },
        },
    },

    -- ---- User Commands -----------------------------------------------------
    -- Configure buffer local user commands to add when attaching a language server
    commands = {
        Format = {
            function()
                require("conform").format(
                    ---@type conform.FormatOpts
                    {
                        lsp_format = "fallback",
                        timeout_ms = 3000,
                    }
                )
                -- vim.lsp.buf.format()
            end,
            -- condition to create the user command
            -- can either be a string of a client capability or a function of `fun(client, bufnr): boolean`
            cond = "textDocument/formatting",
            -- the rest of the user command options (:h nvim_create_user_command)
            desc = "Format file with LSP",
        },
    },

    -- ---- Capabilities ------------------------------------------------------
    -- Configure default capabilities for language servers (`:h vim.lsp.protocol.make_client.capabilities()`)
    capabilities = require("blink.cmp").get_lsp_capabilities {
        textDocument = {
            foldingRange = {
                dynamicRegistration = true,
            },
        },
    },

    -- ---- Defaults ----------------------------------------------------------
    defaults = {
        hover = {
            border = "rounded",
            silent = true,
        }, -- customize lsp hover window
        signature_help = true, -- disable any default customizations
    },

    -- ---- File Operations ---------------------------------------------------
    -- Configuration of LSP file operation functionality
    file_operations = {
        -- the timeout when executing LSP client operations
        timeout = 10000,
        -- fully disable/enable file operation methods
        operations = {
            willRename = true,
            didRename = true,
            willCreate = true,
            didCreate = true,
            willDelete = true,
            didDelete = true,
        },
    },

    -- ---- Flags -------------------------------------------------------------
    -- A custom flags table to be passed to all language servers  (`:h lspconfig-setup`)
    flags = {
        exit_timeout = 5000,
    },

    -- --- Formatting ---------------------------------------------------------
    -- Configuration options for controlling formatting with language servers
    formatting = {
        -- control auto formatting on save
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
            -- disable format on save for specified filetypes
            -- ignore_filetypes = {
            --     "python",
            -- },
        },
        -- disable formatting capabilities for specific language servers
        -- disabled = {
        --     "lua_ls",
        -- },
        -- default format timeout
        timeout_ms = 1000,
        -- fully override the default formatting function
        -- filter = function(client)
        --     return true
        -- end,
    },

    -- ---- Handlers ----------------------------------------------------------
    -- Configure how language servers get set up
    handlers = {
        -- default handler, first entry with no key
        function(server, opts)
            vim.lsp.config(server, opts)
            vim.lsp.enable(server)
            -- require("lspconfig")[server].setup(opts)
        end,
    },

    --- ---- Servers ----------------------------------------------------------
    -- A list like table of servers that should be setup, useful for enabling language servers not installed with Mason.
    servers = {
        "ast_grep",
        "autotools_ls",

        -- Lua
        "lua_ls",

        -- Json
        "jsonls",

        -- Toml
        "taplo",

        -- Bash
        "bashls",

        -- Python
        "ruff",
        "basedpyright",
        "pyrefly",
        -- "pylsp",
        -- "ty",
        -- "zuban",

        -- C/C++
        "neocmake",
        "clangd",

        -- Typescript/JavaScript
        "ts_ls",

        -- Rust
        "rust_analyzer",

        -- Zig
        "zls",

        -- Godot
        "gdscript",

        "sonarlint",
    },

    -- ---- Server Configurations ---------------------------------------------
    -- Configure language servers for `lspconfig` (`:h lspconfig-setup`)
    config = {
        -- sonarlint = {
        --     server = {
        --         cmd = {
        --             "sonarlint-language-server",
        --             -- Ensure that sonarlint-language-server uses stdio channel
        --             "-stdio",
        --             "-analyzers",
        --             -- paths to the analyzers you need, using those for python and java in this example
        --             vim.fn.expand "$MASON/share/sonarlint-analyzers/sonarpython.jar",
        --             vim.fn.expand "$MASON/share/sonarlint-analyzers/sonarcfamily.jar",
        --             vim.fn.expand "$MASON/share/sonarlint-analyzers/sonarjava.jar",
        --         },
        --     },
        --     filetypes = { "python", "javascript", "typescript", "c", "cpp", "zig", "rust" },
        -- },

        -- Python LSP
        -- ty = {
        --     settings = {
        --         ty = {
        --             diagnosticMode = "workspace",
        --         },
        --     },
        -- },

        -- Cmake LSP
        -- cmakels = {
        --     settings = {
        --         cmake = {
        --             cmd = { "cmake-language-server" },
        --             filetypes = { "cmake" },
        --             root_markers = { "CMakePresets.json", "CTestConfig.cmake", ".git", "build", "cmake" },
        --             init_options = {
        --                 buildDirectory = "build",
        --             },
        --         },
        --     },
        -- },
        neocmake = {
            settings = {
                neocmake = {
                    buildDirectory = "build",
                },
            },
        },

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

        -- pylsp = {
        --     settings = {
        --         pylsp = {
        --             configurationSources = {},
        --             plugins = {
        --                 black = { enabled = false },
        --                 autopep8 = { enabled = false },
        --                 yapf = { enabled = false },
        --                 pylint = { enabled = false },
        --                 pyflakes = { enabled = false },
        --                 pycodestyle = { enabled = false },
        --                 pylsp_mypy = { enabled = false },
        --                 mypy = { enabled = false },
        --                 jedi_completion = {
        --                     enabled = true,
        --                     fuzzy = true,
        --                 },
        --                 jedi_definition = {
        --                     enabled = true,
        --                     follow_imports = true,
        --                     follow_builtin_imports = true,
        --                     follow_builtin_definitions = true,
        --                 },
        --                 jedi_hover = { enabled = true },
        --                 jedi_references = { enabled = true },
        --                 jedi_signature_help = { enabled = true },
        --                 jedi_symbols = {
        --                     enabled = true,
        --                     all_scopes = true,
        --                 },
        --                 pyls_isort = { enabled = false },
        --                 ruff = {
        --                     enabled = true,
        --                 },
        --             },
        --         },
        --     },
        -- },
    },

    --- ---- on_attach --------------------------------------------------------
    on_attach = function(client, bufnr)
        client.server_capabilities.semanticTokensProvider = nil

        local snacks = require "snacks"
        local kind_filter = {
            default = {
                "Class",
                "Constructor",
                "Enum",
                "Field",
                "Function",
                "Interface",
                "Method",
                "Module",
                "Namespace",
                "Package",
                "Property",
                "Struct",
                "Trait",
            },
            markdown = false,
            help = false,
            -- you can specify a different filter for each filetype
            lua = {
                "Class",
                "Constructor",
                "Enum",
                "Field",
                "Function",
                "Interface",
                "Method",
                "Module",
                "Namespace",
                -- remove package since luals uses it for control flow structures
                -- "Package",
                "Property",
                "Struct",
                "Trait",
            },
        }

        -- Check if the client supports the given method.
        local function is_supported_method(method, client_)
            if client_.supports_method and client_:supports_method(method) then
                return true
            end

            return false
        end

        -- Set up custom LSP keybindings.
        vim.keymap.set({ "n" }, "K", function()
            vim.lsp.buf.hover { border = "rounded" }
        end, { noremap = true, buffer = bufnr, desc = "LSP - Hover" })

        vim.keymap.set("n", "gd", function()
            snacks.picker.lsp_definitions()
        end, { noremap = true, buffer = bufnr, desc = "LSP - Go to Definition" })

        vim.keymap.set("n", "gD", function()
            vim.lsp.buf.declaration()
        end, { noremap = true, buffer = bufnr, desc = "LSP - Go to Declaration" })

        vim.keymap.set("n", "gi", function()
            snacks.picker.lsp_implementations()
        end, { noremap = true, buffer = bufnr, desc = "LSP - Go to Implementation" })

        vim.keymap.set("n", "go", function()
            snacks.picker.lsp_type_definitions()
        end, { noremap = true, buffer = bufnr, desc = "LSP  - Go to type definition" })

        vim.keymap.set("n", "gr", function()
            snacks.picker.lsp_references()
        end, { noremap = true, buffer = bufnr, desc = "LSP - Go to References" })

        -- Add symbol picker keybindings if supported by the LSP server.
        if is_supported_method("documentSymbol", client) then
            vim.keymap.set("n", "<leader>ss", function()
                snacks.picker.lsp_symbols { filter = kind_filter }
            end, { noremap = true, buffer = bufnr, desc = "LSP - Show Symbols" })
        end

        if is_supported_method("workspace/symbols", client) then
            vim.keymap.set("n", "<leader>sS", function()
                snacks.picker.lsp_workspace_symbols { filter = kind_filter }
            end, { noremap = true, buffer = bufnr, desc = "LSP - Show Workspace Symbols" })
        end
    end,
}

-- Configure LSP servers.
-- Override default client capabilities to disable file watching.
local client_caps = vim.lsp.protocol.make_client_capabilities()

if client_caps.workspace then
    client_caps.workspace.didChangeWatchedFiles = nil
end

vim.tbl_map(astrolsp.lsp_setup, astrolsp.config.servers)
