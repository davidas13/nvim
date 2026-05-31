-- Intallation {{{
local specs = require "specs"

vim.pack.add {
    specs["glslView-nvim"],
}
-- }}}

-- Setup {{{
require("glslView").setup {
    viewer_path = "glslViewer",
    args = { "-l" },
}
-- }}}
