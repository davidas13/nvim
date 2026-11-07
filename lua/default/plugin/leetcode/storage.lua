-- Setup ------------------------------------------------------------------- {{{
-- Storage paths for problems and cache.
---@type lc.storage
return {
    home = vim.fn.stdpath "data" .. "/leetcode",
    cache = vim.fn.stdpath "cache" .. "/leetcode",
}
-- }}}
