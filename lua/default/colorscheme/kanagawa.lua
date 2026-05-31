-- Installation {{{
local specs = require "specs"

vim.pack.add {
    specs["kanagawa-paper.nvim"],
    specs["kanagawa.nvim"],
}
-- }}}

-- Setup {{{
require("kanagawa").setup {
    transparent = true,
    theme = "wave",
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
        palette = {
            -- ============================================================
            -- Monochrome palette — revised for consistency
            --
            -- Prinsip:
            --   • sumiInk  : cool-tinted dark, tiap step +6–10 hex unit
            --   • dragon syntax : 9 tangga lightness (step 8 hex), tint
            --                     warm(BB-4) / netral(BB=RG) / cool(BB+4)
            --   • Lotus / Canvas: diselaraskan tapi dipertahankan karakternya
            -- ============================================================

            -- ----------------------------------------------------------------
            -- BACKGROUND — sumiInk (cool blue-purple tint)
            -- Tiap rung naik ~6–10 unit dari rung sebelumnya
            -- ----------------------------------------------------------------
            sumiInkn1 = "#0f0f15", -- floor
            sumiInk0 = "#181820", -- +9  base dark bg
            sumiInk1 = "#1d1d26", -- +5  panel bg gelap
            sumiInk2 = "#21212c", -- +4  normal bg
            sumiInk3 = "#202028", -- +5  main bg
            sumiInk4 = "#2e2e3a", -- +8  selection / panel
            sumiInk5 = "#3d3d4a", -- +f  visual / inactive
            sumiInk6 = "#595968", -- +1c gutter / nontext

            -- ----------------------------------------------------------------
            -- BACKGROUND — dragonBlack (neutral warm, dipertahankan)
            -- ----------------------------------------------------------------
            dragonBlack0 = "#0f0f0f",
            dragonBlack1 = "#131312",
            dragonBlack2 = "#1a1a18",
            dragonBlack3 = "#181714",
            dragonBlack4 = "#252524",
            dragonBlack5 = "#353533",
            dragonBlack6 = "#5c5c58",

            -- ----------------------------------------------------------------
            -- BACKGROUND — winter / wave (diff bg accents, tint kuat tapi gelap)
            -- ----------------------------------------------------------------
            waveBlue1 = "#252534", -- lebih biru dari sumi
            waveBlue2 = "#464658",
            winterBlue = "#23233a", -- paling biru
            winterGreen = "#2b2e2a", -- sedikit hijau
            winterRed = "#302a2b", -- sedikit merah
            winterYellow = "#2c2a24", -- sedikit kuning

            -- ----------------------------------------------------------------
            -- FOREGROUND
            -- ----------------------------------------------------------------
            fujiWhite = "#d2d2ca", -- warm-neutral, fg utama
            dragonWhite = "#bcbcb8", -- sedikit warm
            oldWhite = "#b0aba0", -- warm

            -- ================================================================
            -- SYNTAX COLORS — 9 tangga lightness, step ±8 hex
            --
            --   Rung  Hex   Peran
            --   ----  ----  --------------------------------------------------
            --     1   #6c   comment, deprecated
            --     2   #78   ok/added (vcs), info accent
            --     3   #80   docstring, subtle syntax
            --     4   #88   string literal
            --     5   #90   function, statement
            --     6   #96   type, hint
            --     7   #9e   keyword, number
            --     8   #a6   constant, parameter, punct
            --     9   #ae   operator, member
            --    10   #b6   identifier, attribute (paling terang)
            --
            --  Tint: warm = BB − 4, netral = BB == RG, cool = BB + 4
            -- ================================================================

            -- Rung 1 (~#6c) ─ comment, deprecated
            fujiGray = "#6c6c68", -- warm  → syn.comment
            katanaGray = "#6c6c6c", -- netral → syn.deprecated

            -- Rung 2 (~#78) ─ ok/vcs added, info, accent rendah
            dragonGreen = "#787874", -- warm  → vcs.added, diag.ok, term.green
            dragonBlue = "#78787c", -- cool  → diag.info, accent1

            -- Rung 3 (~#80) ─ docstring, subtle
            dragonGreen3 = "#80807c", -- warm  → syn.docstring
            dragonBlue3 = "#808080", -- netral → filler / rainbow
            dragonGray3 = "#808080", -- netral → accent4
            dragonBlue4 = "#7c7c7a", -- warm  → filler
            dragonBlue5 = "#5c5c60", -- dark cool → border, term.blue (sengaja gelap)

            -- Rung 4 (~#88) ─ string literal
            dragonGreen2 = "#888880", -- warm  → syn.string
            dragonAsh = "#888886", -- netral → rainbow6

            -- Rung 5 (~#90) ─ function, statement
            dragonViolet = "#8c8c88", -- warm  → syn.statement   (berbeda dari dragonBlue2)
            dragonBlue2 = "#909090", -- netral → syn.fun         (beda 4 unit dari dragonViolet)

            -- Rung 6 (~#96) ─ type, hint
            dragonAqua = "#969694", -- cool  → syn.type, diag.hint  (bukan lagi = springViolet1!)
            dragonTeal = "#969698", -- cool  → rainbow7
            springViolet1 = "#929292", -- netral → bg_search, bg_visual (UI; bukan syntax)

            -- Rung 7 (~#9e) ─ keyword, number
            dragonPink = "#9e9e9a", -- warm  → syn.keyword, syn.number
            springViolet2 = "#9e9e9e", -- netral → misc

            -- Rung 8 (~#a6) ─ constant, parameter, punct, regex
            dragonOrange = "#a6a69e", -- warm  → syn.constant
            dragonOrange2 = "#a2a29a", -- warm  → diff.conflict_ancestor
            dragonGray = "#a6a6a2", -- warm  → syn.parameter
            dragonGray2 = "#a4a4a0", -- warm  → syn.punct

            -- Rung 9 (~#ae) ─ operator, member, symbol
            dragonRed = "#aeaea8", -- warm  → syn.operator, syn.member, syn.symbol

            -- Rung 10 (~#b4-b6) ─ identifier, attribute (paling terang)
            dragonYellow = "#b4b4ac", -- warm  → syn.identifier, syn.attribute

            -- ================================================================
            -- MISC SYNTAX / RAINBOW
            -- ================================================================
            crystalBlue = "#9a9a96",
            springGreen = "#9a9a92",
            springBlue = "#9c9c9a",
            waveRed = "#9a9a90",
            boatYellow1 = "#888880",
            boatYellow2 = "#989890",
            carpYellow = "#b8b8a8",
            peachRed = "#b8b8a8",
            roninYellow = "#c0c0a0",
            samuraiRed = "#a0a090",
            sakuraPink = "#b0a8a0",
            lightBlue = "#a8a8a8",
            surimiOrange = "#b8a8a0",
            oniViolet = "#9a9a90",
            oniViolet2 = "#a8a8a4",
            autumnGreen = "#8a8a7f",
            autumnRed = "#a0a09a",
            autumnYellow = "#a8a898",

            -- ================================================================
            -- LOTUS (light-theme variant) — sedikit dirapikan, karakter dijaga
            -- ================================================================
            lotusInk0 = "#3d3d4a",
            lotusInk1 = "#505056",
            lotusInk2 = "#4a4a58",

            lotusWhite0 = "#c0c0b0",
            lotusWhite1 = "#c8c0b0",
            lotusWhite2 = "#d0c8b0",
            lotusWhite3 = "#d8d0b8",
            lotusWhite4 = "#c8c0a0",
            lotusWhite5 = "#c0b8a0",

            lotusGray = "#c8c8bc",
            lotusGray2 = "#7a7a72",
            lotusGray3 = "#8a8a82",

            lotusAqua = "#6a6a66",
            lotusAqua2 = "#7a7a74",

            lotusBlue1 = "#bfbfb9",
            lotusBlue2 = "#b0b0aa",
            lotusBlue3 = "#a5a59f",
            lotusBlue4 = "#7a7a90",
            lotusBlue5 = "#7a7a8a",

            lotusCyan = "#d0d0ca",

            lotusGreen = "#7a7a66",
            lotusGreen2 = "#7a7a70",
            lotusGreen3 = "#a8a8a0",

            lotusOrange = "#909080",
            lotusOrange2 = "#a0a088",
            lotusPink = "#8f8f7a",

            lotusRed = "#a0a090",
            lotusRed2 = "#a8a8a0",
            lotusRed3 = "#b0b0a0",
            lotusRed4 = "#a5a5a0",

            lotusTeal1 = "#7a7a8a",
            lotusTeal2 = "#8a8a9a",
            lotusTeal3 = "#6a6a76",

            lotusViolet1 = "#9a9a96",
            lotusViolet2 = "#7a7a7a",
            lotusViolet3 = "#b5b5ba",
            lotusViolet4 = "#6a6a76",

            lotusYellow = "#5a5a4a",
            lotusYellow2 = "#6a6a5a",
            lotusYellow3 = "#888880",
            lotusYellow4 = "#c0b8a0",

            -- ================================================================
            -- CANVAS (variant netral) — diselaraskan ke tangga yang sama
            -- ================================================================
            canvasAqua1 = "#8a8a88",
            canvasAsh1 = "#7a7a76",
            canvasBlue1 = "#909090",
            canvasBlue2 = "#8a8a88",
            canvasBlue3 = "#808080",
            canvasBlue4 = "#7a7a78",
            canvasBlue5 = "#6a6a68",
            canvasCyan1 = "#858580",
            canvasGray1 = "#a8a8a6",
            canvasGray2 = "#8e8e8a",
            canvasGray3 = "#808080",
            canvasGreen1 = "#8a8a85",
            canvasGreen2 = "#8a8a80",
            canvasGreen3 = "#9a9a94",
            canvasOrange1 = "#9a9a90",
            canvasOrange2 = "#949490",
            canvasPink1 = "#909090",
            canvasPink2 = "#b0b0ac",
            canvasPink3 = "#c5c5c0",
            canvasRed1 = "#a8a8a4",
            canvasTeal1 = "#909090",
            canvasViolet1 = "#868684",
            canvasViolet2 = "#9a9a98",
            canvasWhite1 = "#c5c5bf",
            canvasWhite2 = "#c8c8be",
            canvasWhite3 = "#cfcfc9",
            canvasWhite4 = "#d8d8d4",
            canvasWhite5 = "#dcdcd9",
            canvasWhite6 = "#e2e2de",
            canvasYellow1 = "#9a9a8c",
            canvasYellow2 = "#a8a8a0",
        },
    },
}
-- }}}

-- Implementation {{{
-- vim.cmd [[colorscheme kanagawa]]
vim.cmd [[colorscheme kanagawa-paper]]
-- }}}
