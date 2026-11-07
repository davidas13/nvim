-- Setup ------------------------------------------------------------------- {{{
-- Debug adapters installed through mason.
local dap = require "dap"

dap.adapters.codelldb = {
    type = "server",
    port = "${port}",
    executable = {
        command = vim.fn.stdpath "data" .. "/mason/bin/codelldb",
        args = { "--port", "${port}" },
    },
}

dap.adapters.cppdbg = {
    id = "cppdbg",
    type = "executable",
    command = vim.fn.stdpath "data" .. "/mason/bin/cppdbg",
}

-- vscode-js-debug serves every pwa-* adapter type from one DAP server.
local js_debug_adapter = vim.fn.stdpath "data" .. "/mason/bin/js-debug-adapter"
for _, adapter_name in ipairs { "pwa-node", "pwa-chrome" } do
    dap.adapters[adapter_name] = {
        type = "server",
        host = "127.0.0.1",
        port = "${port}",
        executable = {
            command = js_debug_adapter,
            args = { "${port}" },
        },
    }
end
-- }}}
