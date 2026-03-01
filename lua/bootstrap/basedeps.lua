--- Install basic dependencies

---@param source string
---@param dest string
---@return boolean
local function download(source, dest)
    if vim.fn.empty(vim.fn.glob(dest)) > 0 then
        vim.cmd['!']("git", "clone", source, dest)
        return true
    end
    return false
end


local function setup()
    local j = vim.fs.joinpath

    local packages = j(_G.STDPATH.data, "site/pack/base")
    local fennel_root =  j(packages, "/opt/fennel")
    local fennel_extra_rtp = j(fennel_root, "/rtp")

    local isnew = download("https://github.com/bakpakin/Fennel", fennel_root)

    vim.cmd("packadd fennel")

    if isnew then
        require "bootstrap.fennel.ensure_compiler".setup()
    end

    vim.opt.runtimepath:append(fennel_extra_rtp)
end


return { setup = setup }

--- basedeps.lua ends here
