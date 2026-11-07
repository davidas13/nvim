-- Setup ------------------------------------------------------------------- {{{
-- blink.cmp completion menu and documentation windows.
return {
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
}
-- }}}
