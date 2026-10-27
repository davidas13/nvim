-- Installation ------------------------------------------------------------ {{{
local specs = require "specs"

vim.pack.add {
    specs["volt"],
    specs["triforce.nvim"],
    specs["lualine.nvim"],
}
-- }}}

-- Setup ------------------------------------------------------------------- {{{
local triforce = require("triforce.lualine").components()

require("lualine").setup {
    options = {
        section_separators = { left = "", right = "" },
        component_separators = { left = "", right = "" },
    },
    sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        -- lualine_c = { { "filename", path = 1 }, "lsp_progress" },
        lualine_c = { { "filename", path = 1 } },
        lualine_x = {
            triforce.level,
            triforce.achievements,
            triforce.streak,
            triforce.session_time,
            function()
                local statusline = require("arrow.statusline").text_for_statusline_with_icons()

                if not statusline then
                    return ""
                end

                return statusline
            end,
            "encoding",
            "fileformat",
            "filetype",
        },
        lualine_y = { "progress" },
        lualine_z = { "location" },
    },
    -- tabline = {
    --     lualine_a = { { "tabs", mode = 2 } },
    --     lualine_b = {},
    --     lualine_c = {},
    --     lualine_x = {},
    --     lualine_y = {},
    --     lualine_z = { { "buffers" } },
    -- },
}
-- }}}
