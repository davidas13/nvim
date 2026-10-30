-- Skip outside an Obsidian vault: a vault is a directory that holds a
-- ".obsidian" folder, so the vault root is the closest ancestor of the working
-- directory carrying that marker.
-- shortcut: checks cwd at startup only, re-entering a vault after :cd needs a restart
local vault_root = vim.fs.root(vim.fn.getcwd(), { ".obsidian" })

-- Installation ------------------------------------------------------------ {{{
local specs = require "specs"

vim.pack.add {
    specs["obsidian.nvim"],
}
-- }}}

-- Setup ------------------------------------------------------------------- {{{
-- The plugin registers its command, autocmds and its LSP for markdown buffers,
-- so setup runs only when the working directory sits inside a vault.
if vault_root then
    require("obsidian").setup {
        legacy_commands = false,
        workspaces = {
            {
                name = vim.fs.basename(vault_root),
                path = vault_root,
            },
        },
        picker = {
            name = "snacks.picker",
        },
    }
end
-- }}}
