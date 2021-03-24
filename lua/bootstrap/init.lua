
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
    vim.cmd "autocmd VimEnter * ++once lua pcall(_T, 'after', 'setup')"
end

return M
