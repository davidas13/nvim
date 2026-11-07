-- Setup ------------------------------------------------------------------- {{{
-- Lifecycle hooks.
return {
    ---@type fun()[]
    ["enter"] = {},

    ---@type fun(question: lc.ui.Question)[]
    ["question_enter"] = {},

    ---@type fun()[]
    ["leave"] = {},
}
-- }}}
