-- Buffer local mappings and behavior added when a language server attaches.
return function(client, bufnr)
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
        -- a different filter can be set per filetype
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
            -- Package is left out because lua_ls uses it for control flow structures
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

    vim.keymap.set({ "n" }, "K", function()
        vim.lsp.buf.hover { border = "rounded", focusable = true }
    end, { noremap = true, buffer = bufnr, desc = "LSP - Hover" })

    vim.keymap.set({ "n" }, "gh", function()
        vim.diagnostic.open_float { focusable = true, { border = "rounded" } }
    end, { noremap = true, buffer = bufnr, desc = "LSP - Show Diagnostics" })

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

    vim.keymap.set("n", "gR", function()
        vim.lsp.buf.rename()
    end, { noremap = true, buffer = bufnr, desc = "LSP - Rename" })

    vim.keymap.set("n", "ga", function()
        vim.lsp.buf.code_action()
    end, { noremap = true, buffer = bufnr, desc = "LSP - Code Action" })

    -- Symbol pickers only bind when the client supports their LSP method.
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
end
