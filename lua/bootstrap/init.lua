
local M = {}


function M.setup()
    if os.getenv("AK_PROFILER") then
        vim.cmd "packadd profiler"
        require("profiler")
    end

    -- Download package manager and friends
    require("bootstrap.basedeps").setup()
    require("bootstrap.trampouline").setup() 
    require("bootstrap.reload").setup()
    require("bootstrap.modules").setup()
    require("bootstrap.fennel").setup()
    require("bootstrap.gui").setup()
    require("my").setup()

    -- Execute after module
    local function init_package(package_name, ...)
        local ok, res = xpcall(function()
            return require(package_name)
        end, debug.traceback)

        if ok then
            if res then
                if vim.is_callable(res) then
                    return res(...)
                elseif vim.is_callable(res.setup) then
                    return res.setup(...)
                end
            end
        else
            local errmsg = string.format("module '%s' not found", package_name)
            if not vim.startswith(res, errmsg) then
                vim.notify(res:gsub("\t", "    "), vim.log.levels.ERROR)
            end
        end
    end

    init_package("after")
end

return M
