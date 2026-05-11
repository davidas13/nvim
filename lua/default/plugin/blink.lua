-- ==== Intallation ===========================================================
--
vim.pack.add {
    { src = "https://github.com/echasnovski/mini.snippets" },
    { src = "https://github.com/echasnovski/mini.icons" },
    { src = "https://github.com/mikavilpas/blink-ripgrep.nvim" },
    { src = "https://github.com/rafamadriz/friendly-snippets" },
    { src = "https://github.com/onsails/lspkind.nvim" },
    { src = "https://github.com/AstroNvim/astrolsp" },

    -- AI plugins.
    -- Copilot
    -- NOTE: Disabled until I subscribe again.
    -- { src = "https://github.com/zbirenbaum/copilot.lua" },
    -- { src = "https://github.com/fang2hou/blink-copilot" },
    -- { src = "https://github.com/copilotlsp-nvim/copilot-lsp" },
    -- Supermaven
    { src = "https://github.com/supermaven-inc/supermaven-nvim" },
    { src = "https://github.com/huijiro/blink-cmp-supermaven" },

    { src = "https://github.com/saghen/blink.compat" },

    -- Main Plugin.
    { src = "https://github.com/saghen/blink.cmp" },
}

-- ==== Setup =================================================================
--
require("blink.compat").setup {}

local blink = require "blink.cmp"

blink.setup {
    appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = "mono",
    },
    sources = {
        default = {
            "lsp",
            "path",
            "snippets",
            "supermaven",
            -- "copilot",
            -- "buffer",
            -- "ripgrep",
        },
        providers = {
            lsp = {
                score_offset = 100,
            },
            path = {
                score_offset = 8,
            },
            snippets = {
                score_offset = 7,
            },
            buffer = {
                score_offset = 6,
            },
            supermaven = {
                score_offset = -1,
                name = "supermaven",
                module = "blink-cmp-supermaven",
                async = true,
            },
            -- copilot = {
            --     name = "copilot",
            --     module = "blink-copilot",
            --     score_offset = -1,
            --     async = true,
            -- },
            -- ripgrep = {
            --     module = "blink-ripgrep",
            --     name = "Ripgrep",
            --     -- see the full configuration below for all available options
            --     ---@module "blink-ripgrep"
            --     ---@type blink-ripgrep.Options
            --     opts = {},
            --     async = true,
            --     score_offset = 5,
            -- },
        },
    },
    fuzzy = {
        implementation = "prefer_rust_with_warning",
        sorts = {
            "score",
            "sort_text",
            "exact",
            "label",
            -- "kind",
        },
        use_proximity = true,
    },
    keymap = {
        ["<c-k>"] = { "show", "show_documentation", "hide_documentation" },
        ["<up>"] = { "select_prev", "fallback" },
        ["<down>"] = { "select_next", "fallback" },
        ["<c-n>"] = { "select_next", "show" },
        ["<c-p>"] = { "select_prev", "show" },
        ["<c-u>"] = { "scroll_documentation_up", "fallback" },
        ["<c-d>"] = { "scroll_documentation_down", "fallback" },
        ["<c-e>"] = { "hide", "fallback" },
        ["<cr>"] = { "accept", "fallback" },
    },
    completion = {
        trigger = { prefetch_on_insert = false },
        list = { selection = { preselect = false, auto_insert = false } },
        menu = {
            max_height = 30,
            draw = {
                columns = {
                    { "label", "label_description", gap = 1 },
                    { "kind_icon" },
                    { "source_name" },
                },
                -- Padding only on right side.
                padding = { 0, 1 },
            },
            auto_show = function(ctx)
                return ctx.mode ~= "cmdline"
            end,
            border = "rounded",
            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
            scrollbar = true,
            scrolloff = 2,
        },
        accept = {
            auto_brackets = { enabled = true },
        },
        documentation = {
            auto_show = true,
            auto_show_delay_ms = 0,
            window = {
                border = "rounded",
                winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
            },
        },
    },
    signature = {
        enabled = true,
        window = {
            border = "rounded",
            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
        },
    },
    cmdline = {
        keymap = {
            ["<End>"] = { "hide", "fallback" },
        },
        completion = { ghost_text = { enabled = true } },
    },
    snippets = { preset = "mini_snippets" },
}

-- How to make blink active in InserEnter
-- vim.api.nvim_create_autocmd("InsertEnter", {
--     callback = function()
--         blink.start()
--     end,
-- })
