-- Formatter overrides for custom commands and arguments.
return {
    clang_format = {
        command = "clang-format",
        prepend_args = {
            "--style={BasedOnStyle: LLVM, BreakBeforeBraces: Allman, IndentWidth: 4, IndentCaseLabels: true, ColumnLimit: 80, PointerAlignment: Left , AlignConsecutiveAssignments: true, AlignConsecutiveDeclarations: true, }",
        },
    },
    cmake_format = {
        command = "cmake-format",
        prepend_args = { "-i" },
    },
    prettier = {
        prepend_args = { "--tab-width", "4" },
    },
    injected = {
        options = {
            ignore_errors = true,
        },
    },
}
