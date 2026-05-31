-- ==== Intallation ===========================================================
--
local specs = require "specs"

vim.pack.add {
    specs["snacks.nvim"],
    specs["gitsigns.nvim"],
}

-- ==== Setup =================================================================
--
require("gitsigns").setup {
    signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
    },
    signs_staged = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
    },
    on_attach = function(bufnr)
        local gitsigns = require "gitsigns"

        local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map("n", "]c", function()
            if vim.wo.diff then
                vim.cmd.normal { "]c", bang = true }
            else
                gitsigns.nav_hunk "next"
            end
        end)

        map("n", "[c", function()
            if vim.wo.diff then
                vim.cmd.normal { "[c", bang = true }
            else
                gitsigns.nav_hunk "prev"
            end
        end)

        -- Actions
        map("n", "<leader>ghs", function()
            gitsigns.stage_hunk()
        end, { desc = "Stage Hunk" })

        map("n", "<leader>ghr", function()
            gitsigns.reset_hunk()
        end, { desc = "Reset Hunk" })

        map("v", "<leader>ghs", function()
            gitsigns.stage_hunk { vim.fn.line ".", vim.fn.line "v" }
        end, { desc = "Stage Hunk" })

        map("v", "<leader>ghr", function()
            gitsigns.reset_hunk { vim.fn.line ".", vim.fn.line "v" }
        end, { desc = "Reset Hunk" })

        map("n", "<leader>ghS", function()
            gitsigns.stage_buffer()
        end, { desc = "Stage Buffer" })

        map("n", "<leader>ghR", function()
            gitsigns.reset_buffer()
        end, { desc = "Reset Buffer" })

        map("n", "<leader>gh<space>", function()
            gitsigns.refresh()
        end, { desc = "Refresh Buffer" })

        map("n", "<leader>ghp", gitsigns.preview_hunk, { desc = "Preview Hunk" })

        map("n", "<leader>ghi", gitsigns.preview_hunk_inline, { desc = "Preview Hunk Inline" })

        map("n", "<leader>ghb", function()
            gitsigns.blame_line { full = true }
        end, { desc = "Blame Line" })

        map("n", "<leader>ghd", gitsigns.diffthis, { desc = "Diff This" })

        map("n", "<leader>ghD", function()
            gitsigns.diffthis "~"
        end, { desc = "Diff This ~" })

        map("n", "<leader>ghQ", function()
            gitsigns.setqflist "all"
        end, { desc = "Set QF List" })
        map("n", "<leader>ghq", gitsigns.setqflist, { desc = "Set QF List" })

        -- Toggles
        map("n", "<leader>thb", gitsigns.toggle_current_line_blame, { desc = "Toggle Current Line Blame" })
        map("n", "<leader>thw", gitsigns.toggle_word_diff, { desc = "Toggle Word Diff" })

        -- Text object
        map({ "o", "x" }, "gih", gitsigns.select_hunk, { desc = "Select Hunk" })
    end,
}

require("snacks")
    .toggle({
        name = "Git Signs",
        get = function()
            return require("gitsigns.config").config.signcolumn
        end,
        set = function(state)
            require("gitsigns").toggle_signs(state)
        end,
    })
    :map "<leader>tG"
