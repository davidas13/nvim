-- ==== Load configurations ===================================================
--
local config_file = vim.fn.stdpath "data" .. "/chosen_config"

local function load_config(name)
    vim.fn.writefile({ name }, config_file)
    vim.cmd [[restart]]
end

local function select_config()
    vim.ui.select({ "minimal", "default" }, { prompt = "Choose Neovim config:" }, function(choice)
        if choice then
            load_config(choice)
            vim.notify("Loaded config: " .. choice)
        end
    end)
end

-- Create user command
vim.api.nvim_create_user_command("Config", function()
    select_config()
end, {})

-- Load saved config or ask once
local saved = vim.fn.filereadable(config_file) == 1 and vim.fn.readfile(config_file)[1]

if saved then
    require(saved)
else
    select_config()
end

-- ==== Set Neovim as Git editor if nvr is available ==========================
--
if vim.fn.has "nvim" == 1 and vim.fn.executable "nvr" == 1 then
    vim.env.GIT_EDITOR = "nvr -cc split --remote-wait +'set bufhidden=wipe'"
end
