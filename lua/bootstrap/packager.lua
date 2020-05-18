--- vim-packager module
--

local callback = require "bootstrap.callback"

local M = {}


local function M.init()
    vim.fn["packager#init"]()
end


local function adder(source, dest)
    return function(name, callback)
        local v = source[name]
        if v ~= nil then
            if callback ~= nil then
                v = callback(v)
            end
            dest[name] = v
        end
    end
end


local function M.add(url, opts)
    local arg = { url }

    if nil ~= opts and nil ~= next(opts) then
        local o = {}

        local add = function(name, cb)
            local v = opts[name]
            if v ~= nil then
                if cb ~= nil then
                    v = cb(v)
                end
                o[name] = v
            end
        end

        add("name")
        add("type")
        add("branch")
        add("tag")
        add("rtp")

        add("do")
        add("frozen")

        if nil ~= next(o) then
            arg[2] = o
        end
    end

    return apply("packager#add", arg, {[1] = 'do'})
end


local function M.localpkg()

end


local function M.install()
end


local function M.update()
    local arg = { url }
    if nil ~= cb then
        arg[2] = { ["do"] = callback.make(cb) }
    end
    return vim.fn["packager#update"](arg)
end


local function M.status()
    return vim.fn['packager#status']()
end


local function M.download()
    local config = vim.api.nvim_call_function("stdpath", {"config"})
    local path = config .. "/pack/packager/opt/vim-packager/"
    local url = "https://github.com/kristijanhusak/vim-packager"
    if vim.api.nvim_call_function("filereadable",
                                  {path .. "LICENSE"}) ~= 1 then
        vim.api.nvim_command(strinf.format("!git clone %q %q", url, path))
    end

    vim.api.nvim_command("packadd minpac")

    M.init()
    M.add("kristijanhusak/vim-packager", { type = "opt" })
end


return M

--- packager.lua ends here
