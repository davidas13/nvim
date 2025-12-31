-- ==== Intallation ===========================================================
--
vim.pack.add {
    -- Main plugin.
    { src = "https://github.com/timtro/glslView-nvim" },
}

-- ==== Setup =================================================================
--
require("glslView").setup {
    viewer_path = "glslViewer",
    args = { "-l" },
}
