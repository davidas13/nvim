-- Lua function to toggle the colorcolumn or set a specific width  {{{
function ToggleColorColumn(size_str)
    local size = tonumber(size_str)
    if size_str ~= nil and size ~= nil then
        -- A valid size was provided
        vim.o.colorcolumn = size_str

        print("ColorColumn set to " .. size .. " characters")
    else
        -- No size was provided, so toggle default (80) or off
        if vim.o.colorcolumn == "" then
            vim.o.colorcolumn = "79, 110" -- Set to 81 to highlight the 80 character limit
            print "ColorColumn enabled at 80 characters"
        else
            vim.o.colorcolumn = ""
            print "ColorColumn disabled"
        end
    end
end
-- }}}

-- Create a Vim command that calls the Lua function {{{
vim.api.nvim_create_user_command("ColorColumnToggle", function(opts)
    ToggleColorColumn(opts.args)
end, { nargs = "?", complete = "expression" })
-- }}}
