-- Installation ------------------------------------------------------------ {{{
local specs = require "specs"

vim.pack.add {
    specs["neoconf.nvim"],
}
-- }}}

-- Setup ------------------------------------------------------------------- {{{
require("neoconf").setup()

-- Settings bridge. astrolsp registers servers through vim.lsp.config, a path
-- that never runs neoconf's own merge hook, so push the merged json settings
-- to each client after it attaches. The public get call leaves keys dotted,
-- so expand them back to nested tables before merging.
local function expand_dotted_keys(settings)
    local out = {}
    for key, value in pairs(settings) do
        local node = out
        local parts = vim.split(key, ".", { plain = true })
        for i = 1, #parts - 1 do
            node[parts[i]] = node[parts[i]] or {}
            node = node[parts[i]]
        end
        node[parts[#parts]] = value
    end
    return out
end

local function apply_neoconf_settings(client, bufnr)
    local ok, neoconf = pcall(require, "neoconf")
    if not ok then
        return
    end
    local merged =
        neoconf.get("lspconfig." .. client.name, nil, { buffer = bufnr })
    if type(merged) ~= "table" or vim.tbl_isempty(merged) then
        return
    end
    local next_settings = vim.tbl_deep_extend(
        "force",
        client.settings or {},
        expand_dotted_keys(merged)
    )
    if vim.deep_equal(client.settings, next_settings) then
        return
    end
    client.settings = next_settings
    client.notify(
        "workspace/didChangeConfiguration",
        { settings = client.settings }
    )
end

vim.api.nvim_create_autocmd("LspAttach", {
    desc = "Apply neoconf json settings to the attached client",
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client then
            apply_neoconf_settings(client, args.buf)
        end
    end,
})

-- Editing a settings file should reach the servers of that project too, the
-- way neoconf's live reload intends. Clients of other projects are skipped
-- because their merged settings stay equal.
vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = { ".neoconf.json", "neoconf.json" },
    desc = "Re-apply neoconf json settings after editing them",
    callback = function()
        for _, client in ipairs(vim.lsp.get_clients()) do
            for bufnr in pairs(client.attached_buffers or {}) do
                apply_neoconf_settings(client, bufnr)
            end
        end
    end,
})
-- }}}
