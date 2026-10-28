-- Console layout and behavior.
return {
    open_on_runcode = true, ---@type boolean

    dir = "row", ---@type lc.direction

    size = { ---@type lc.size
        width = "90%",
        height = "75%",
    },

    result = {
        size = "60%", ---@type lc.size
    },

    testcase = {
        virt_text = true, ---@type boolean

        size = "40%", ---@type lc.size
    },
}
