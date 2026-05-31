-- ==== Intallation ===========================================================
local specs = require "specs"

vim.pack.add {
    specs["iceberg-dark"],
    specs["iceberg.vim"],
}
-- ==== Setup =================================================================
vim.cmd [[colorscheme iceberg]]
