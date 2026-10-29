-- Headless smoke check for every plugin config module in this repo.
--
-- Startup already exercises the active profile, so this script forces the
-- remaining modules to load: the other profile and any module whose config
-- file is idle. A load failure exits with a non-zero status, because a plain
-- headless run can exit 0 even when config loading fails.
local repo = vim.fn.fnamemodify(debug.getinfo(1, "S").source:gsub("^@", ""), ":p:h:h")

local trees = { "default/plugin", "minimal/plugin" }
local loaded, failed = {}, {}

local prefix = repo .. "/lua/"

for _, tree in ipairs(trees) do
    local base = prefix .. tree
    local files = vim.fn.glob(base .. "/**/*.lua", false, true)
    for _, f in ipairs(vim.fn.glob(base .. "/*.lua", false, true)) do
        table.insert(files, f)
    end
    for _, f in ipairs(files) do
        local mod = f:sub(#prefix + 1):gsub("%.lua$", ""):gsub("/init$", ""):gsub("/", ".")
        if not loaded[mod] then
            loaded[mod] = true
            local ok, err = pcall(require, mod)
            if not ok then
                failed[#failed + 1] = mod .. ": " .. tostring(err)
            end
        end
    end
end

for _, f in ipairs(failed) do
    print("SMOKE FAIL " .. f)
end
if #failed > 0 then
    vim.cmd "cquit 1"
end
print(("SMOKE OK %d modules"):format(vim.tbl_count(loaded)))
