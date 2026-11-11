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

    -- Setup Keybindings ------------------------------------------------------- {{{
    require("which-key").add {
        { "<leader>O", mode = "n", group = "Obsidian" },
    }

    -- Each subkey runs one "Obsidian" subcommand from the plugin command table.
    -- Subkeys whose action needs a note read the current markdown buffer.
    local obsidian_commands = {
        n = { "new", "New note" },
        N = { "unique_note", "New unique note" },
        q = { "quick_switch", "Quick switch note" },
        s = { "search", "Search notes" },
        o = { "open", "Open in the Obsidian app" },
        t = { "today", "Open today note" },
        y = { "yesterday", "Open yesterday note" },
        T = { "tomorrow", "Open tomorrow note" },
        d = { "dailies", "Browse daily notes" },
        f = { "follow_link", "Follow link under cursor" },
        c = { "toggle_checkbox", "Toggle checkbox" },
        b = { "backlinks", "Backlinks of note" },
        r = { "rename", "Rename note" },
    }

    for subkey, mapping in pairs(obsidian_commands) do
        vim.keymap.set(
            "n",
            "<leader>O" .. subkey,
            "<cmd>Obsidian " .. mapping[1] .. "<cr>",
            { desc = mapping[2] }
        )
    end
    -- }}}

    -- Markdown Keymaps ------------------------------------------------------- {{{
    -- Buffer local so the LSP "gd" mapping stays intact in non-note buffers of
    -- the vault.
    vim.api.nvim_create_augroup("obsidian_markdown_mappings", {
        clear = true,
    })

    vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        group = "obsidian_markdown_mappings",
        callback = function(args)
            vim.keymap.set(
                "n",
                "gd",
                "<cmd>Obsidian follow_link<cr>",
                { buffer = args.buf, desc = "Follow Obsidian link" }
            )
        end,
    })
    -- }}}
end
-- }}}
