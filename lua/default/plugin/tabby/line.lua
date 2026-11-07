-- Setup ------------------------------------------------------------------- {{{
-- Tab line renderer and its highlight theme.
local theme = {
    fill = "TabLineFill",
    head = "TabLine",
    current_tab = "TabLineSel",
    tab = "TabLine",
    win = "TabLine",
    tail = "TabLine",
}

return function(line)
    return {
        line.tabs().foreach(function(tab)
            local hl = tab.is_current() and theme.current_tab or theme.tab
            return {
                "",
                tab.is_current() and "" or "󰆣",
                tab.number(),
                tab.name(),
                line.sep(" ", hl, theme.fill),
                hl = hl,
                margin = " ",
            }
        end),
        line.spacer(),
        line.wins_in_tab(line.api.get_current_tab()).foreach(function(win)
            return {
                line.sep(" ", theme.win, theme.fill),
                win.is_current() and "" or "",
                win.buf_name() .. " ",
                hl = theme.win,
                margin = " ",
            }
        end),
        hl = theme.fill,
    }
end
-- }}}
