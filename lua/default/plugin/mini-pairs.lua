-- Installation ------------------------------------------------------------ {{{
vim.pack.add {
    { src = "https://github.com/echasnovski/mini.pairs" },
}
-- }}}

-- Setup ------------------------------------------------------------------- {{{
require("mini.pairs").setup {
    modes = {
        insert = true,
        command = false,
        terminal = false,
    },
}
-- }}}

-- Triple delimiters ------------------------------------------------------- {{{
-- mini.pairs maps single characters only, so a third backtick or quote opens
-- another pair instead of closing a fenced block. Take over those two keys in
-- the filetypes that use triple delimiters and keep the single character
-- behavior identical everywhere else.
local function make_triple_mapping(delim)
    local pair = delim .. delim
    local triple = delim:rep(3)
    local newline = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
    local move_up = vim.api.nvim_replace_termcodes("<Up>", true, false, true)

    return function()
        local line = vim.api.nvim_get_current_line()
        local col = vim.api.nvim_win_get_cursor(0)[2]
        local before = line:sub(1, col)
        local after = line:sub(col + 1)

        -- A closing triple to the right means the user is typing over an
        -- existing pair. Let closeopen skip it instead of opening a new block.
        if
            before:sub(-2) == pair
            and before:sub(1, -3):match "^%s*$"
            and after:match "^%s*$"
        then
            return delim .. newline .. newline .. triple .. move_up
        end

        return MiniPairs.closeopen(pair, "^[^\\]")
    end
end

local augroup = vim.api.nvim_create_augroup("TriplePairs", {})

vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = { "markdown", "mdx", "quarto", "rmd" },
    callback = function(args)
        vim.keymap.set("i", "`", make_triple_mapping "`", {
            buffer = args.buf,
            expr = true,
            noremap = true,
            replace_keycodes = false,
        })
    end,
})

vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    pattern = "python",
    callback = function(args)
        vim.keymap.set("i", "\"", make_triple_mapping "\"", {
            buffer = args.buf,
            expr = true,
            noremap = true,
            replace_keycodes = false,
        })
    end,
})
-- }}}
