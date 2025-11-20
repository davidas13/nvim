-- ==== Load configurations ===================================================
--
require "config"
require "colorscheme"
require "plugin"

-- ==== Set Neovim as Git editor if nvr is available ==========================
--
if vim.fn.has "nvim" == 1 and vim.fn.executable "nvr" == 1 then
    vim.env.GIT_EDITOR = "nvr -cc split --remote-wait +'set bufhidden=wipe'"
end

