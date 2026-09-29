-- Installation ----------------------------------------------------------- {{{
local specs = require "specs"

vim.pack.add {
    specs["kanagawa-paper.nvim"],
    specs["kanagawa.nvim"],
}
-- }}}

-- Setup ------------------------------------------------------------------ {{{
require("kanagawa").setup {
    transparent = true,
    -- theme = "wave",
    colors = {
        theme = {
            all = {
                ui = {
                    bg_gutter = "none",
                },
            },
        },
    },
}

require("kanagawa-paper").setup {
    transparent = false,
    colors = {
        theme = {
            ink = {
                syn = {
                    comment = "#5c5c60",
                },
            },
        },
    --     palette = {
    --         -- Dark backgrounds
    --         sumiInkn1 = "#0f0f15",
    --         sumiInk0 = "#181820",
    --         sumiInk1 = "#1d1d26",
    --         sumiInk2 = "#21212c",
    --         sumiInk3 = "#202028",
    --         sumiInk4 = "#2e2e3a",
    --         sumiInk5 = "#3d3d4a",
    --         sumiInk6 = "#595968",
    --
    --         -- Dragon backgrounds
    --         dragonBlack0 = "#0f0f0f",
    --         dragonBlack1 = "#131312",
    --         dragonBlack2 = "#1a1a18",
    --         dragonBlack3 = "#181714",
    --         dragonBlack4 = "#252524",
    --         dragonBlack5 = "#353533",
    --         dragonBlack6 = "#5c5c58",
    --
    --         -- Background accents
    --         waveBlue1 = "#252534",
    --         waveBlue2 = "#464658",
    --         winterBlue = "#23233a",
    --         winterGreen = "#2b2e2a",
    --         winterRed = "#302a2b",
    --         winterYellow = "#2c2a24",
    --
    --         -- Foreground
    --         fujiWhite = "#d2d2ca",
    --         dragonWhite = "#bcbcb8",
    --         oldWhite = "#b0aba0",
    --
    --         -- Syntax
    --         fujiGray = "#5c5c60",
    --         katanaGray = "#6c6c6c",
    --
    --         dragonGreen = "#787874",
    --         dragonBlue = "#78787c",
    --
    --         dragonGreen3 = "#80807c",
    --         dragonBlue3 = "#808080",
    --         dragonGray3 = "#808080",
    --         dragonBlue4 = "#7c7c7a",
    --         dragonBlue5 = "#5c5c60",
    --
    --         dragonGreen2 = "#888880",
    --         dragonAsh = "#888886",
    --
    --         dragonViolet = "#8c8c88",
    --         dragonBlue2 = "#909090",
    --
    --         dragonAqua = "#969694",
    --         dragonTeal = "#969698",
    --         springViolet1 = "#929292",
    --
    --         dragonPink = "#9e9e9a",
    --         springViolet2 = "#9e9e9e",
    --
    --         dragonOrange = "#a6a69e",
    --         dragonOrange2 = "#a2a29a",
    --         dragonGray = "#a6a6a2",
    --         dragonGray2 = "#a4a4a0",
    --
    --         dragonRed = "#aeaea8",
    --         dragonYellow = "#b4b4ac",
    --
    --         -- Additional syntax colors
    --         crystalBlue = "#9a9a96",
    --         springGreen = "#9a9a92",
    --         springBlue = "#9c9c9a",
    --         waveRed = "#9a9a90",
    --
    --         boatYellow1 = "#888880",
    --         boatYellow2 = "#989890",
    --         carpYellow = "#b8b8a8",
    --         peachRed = "#b8b8a8",
    --         roninYellow = "#c0c0a0",
    --         samuraiRed = "#a0a090",
    --         sakuraPink = "#b0a8a0",
    --         lightBlue = "#a8a8a8",
    --         surimiOrange = "#b8a8a0",
    --         oniViolet = "#9a9a90",
    --         oniViolet2 = "#a8a8a4",
    --         autumnGreen = "#8a8a7f",
    --         autumnRed = "#a0a09a",
    --         autumnYellow = "#a8a898",
    --
    --         -- Lotus
    --         lotusInk0 = "#3d3d4a",
    --         lotusInk1 = "#505056",
    --         lotusInk2 = "#4a4a58",
    --
    --         lotusWhite0 = "#c0c0b0",
    --         lotusWhite1 = "#c8c0b0",
    --         lotusWhite2 = "#d0c8b0",
    --         lotusWhite3 = "#d8d0b8",
    --         lotusWhite4 = "#c8c0a0",
    --         lotusWhite5 = "#c0b8a0",
    --
    --         lotusGray = "#c8c8bc",
    --         lotusGray2 = "#7a7a72",
    --         lotusGray3 = "#8a8a82",
    --
    --         lotusAqua = "#6a6a66",
    --         lotusAqua2 = "#7a7a74",
    --
    --         lotusBlue1 = "#bfbfb9",
    --         lotusBlue2 = "#b0b0aa",
    --         lotusBlue3 = "#a5a59f",
    --         lotusBlue4 = "#7a7a90",
    --         lotusBlue5 = "#7a7a8a",
    --
    --         lotusCyan = "#d0d0ca",
    --
    --         lotusGreen = "#7a7a66",
    --         lotusGreen2 = "#7a7a70",
    --         lotusGreen3 = "#a8a8a0",
    --
    --         lotusOrange = "#909080",
    --         lotusOrange2 = "#a0a088",
    --         lotusPink = "#8f8f7a",
    --
    --         lotusRed = "#a0a090",
    --         lotusRed2 = "#a8a8a0",
    --         lotusRed3 = "#b0b0a0",
    --         lotusRed4 = "#a5a5a0",
    --
    --         lotusTeal1 = "#7a7a8a",
    --         lotusTeal2 = "#8a8a9a",
    --         lotusTeal3 = "#6a6a76",
    --
    --         lotusViolet1 = "#9a9a96",
    --         lotusViolet2 = "#7a7a7a",
    --         lotusViolet3 = "#b5b5ba",
    --         lotusViolet4 = "#6a6a76",
    --
    --         lotusYellow = "#5a5a4a",
    --         lotusYellow2 = "#6a6a5a",
    --         lotusYellow3 = "#888880",
    --         lotusYellow4 = "#c0b8a0",
    --
    --         -- Canvas
    --         canvasAqua1 = "#8a8a88",
    --         canvasAsh1 = "#7a7a76",
    --
    --         canvasBlue1 = "#909090",
    --         canvasBlue2 = "#8a8a88",
    --         canvasBlue3 = "#808080",
    --         canvasBlue4 = "#7a7a78",
    --         canvasBlue5 = "#6a6a68",
    --
    --         canvasCyan1 = "#858580",
    --
    --         canvasGray1 = "#a8a8a6",
    --         canvasGray2 = "#8e8e8a",
    --         canvasGray3 = "#808080",
    --
    --         canvasGreen1 = "#8a8a85",
    --         canvasGreen2 = "#8a8a80",
    --         canvasGreen3 = "#9a9a94",
    --
    --         canvasOrange1 = "#9a9a90",
    --         canvasOrange2 = "#949490",
    --
    --         canvasPink1 = "#909090",
    --         canvasPink2 = "#b0b0ac",
    --         canvasPink3 = "#c5c5c0",
    --
    --         canvasRed1 = "#a8a8a4",
    --         canvasTeal1 = "#909090",
    --
    --         canvasViolet1 = "#868684",
    --         canvasViolet2 = "#9a9a98",
    --
    --         canvasWhite1 = "#c5c5bf",
    --         canvasWhite2 = "#c8c8be",
    --         canvasWhite3 = "#cfcfc9",
    --         canvasWhite4 = "#d8d8d4",
    --         canvasWhite5 = "#dcdcd9",
    --         canvasWhite6 = "#e2e2de",
    --
    --         canvasYellow1 = "#9a9a8c",
    --         canvasYellow2 = "#a8a8a0",
    --     },
    },
}
-- }}}

-- Implementation --------------------------------------------------------- {{{
-- vim.cmd [[colorscheme kanagawa]]
vim.cmd [[colorscheme kanagawa-paper]]
-- }}}
