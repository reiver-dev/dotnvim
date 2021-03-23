
local M = {}


function M.setup()
    if os.getenv("AK_PROFILER") then
        vim.cmd "packadd profiler"
        require("profiler")
    end

    -- Download package manager and friends
    require("bootstrap.basedeps").setup()
    require("bootstrap.trampouline").setup() 
    require("bootstrap.fennel").setup()
    require("bootstrap.gui").setup()
    require("my").setup()

    -- Execute after module
    local ok, mod = pcall(function() return require("after") end)
    if ok and type(mod) == "table" and vim.is_callable(mod.setup) then
        mod.setup()
    end
end

return M
