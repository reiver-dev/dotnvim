local callback = require "bootstrap.callback"

local M = {}


function M.init()
    return vim.api.nvim_call_function("minpac#init", {})
end


local function apply(funcname, args, toeval)
    vim.api.nvim_call_function('Apply', {funcname, toeval, args})
end


function M.add(name, opts)
    local arg = { name }

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
        add("frozen")
        add("depth")
        add("branch")
        add("rev")
        add("do")

        if nil ~= next(o) then
            arg[2] = o
        end
    end

    return apply("minpac#add", arg, {[1] = 'do'})
end


function M.update(url, cb)
    local arg = { url }
    if nil ~= cb then
        arg[2] = { ["do"] = callback.make(cb) }
    end
    return vim.fn["minpac#update"](arg)
end


function M.updateall(cb)
    local arg = {}
    if nil ~= cb then
        arg[1] = ""
        arg[2] = { ["do"] = callback.make(cb) }
    end
    return vim.fn["minpac#update"](arg)
end


function M.install()
    return vim.fn["minpac#update"]()
end


function M.download()
    local config = vim.api.nvim_call_function("stdpath", {"config"})
    local path = config .. "/pack/minpac/opt/minpac/"

    if vim.api.nvim_call_function("filereadable",
                                  {path .. ".gitignore"}) ~= 1 then
        vim.api.nvim_command(
            "!git clone https://github.com/k-takata/minpac.git " .. path)

    end

    vim.cmd("packadd minpac")
    M.init()
    M.add("k-takata/minpac", { type = "opt" })
end


function M.getpluginfo(name)
    return vim.api.nvim_call_function("minpac#getpluginfo", {name})
end


function M.getpluglist()
    return vim.api.nvim_call_function("minpac#getpluglist", {})
end


function M.installed(name)
    local res = vim.api.nvim_call_function("minpac#getpackages",
                                           {"", "", name, 1})
    if res ~= nil and #res > 0 then
        return res[1] == name
    else
        return false
    end
end


function M.getpackages(config)
    local arg
    if config == nil then
        arg = {}
    else
        arg = {
            config["name"] or "",
            config["type"] or "",
            config["plug"] or "",
            config["nameonly"] and 1 or 0
        }
    end
    return vim.api.nvim_call_function("minpac#getpackages", arg)
end


function M.status()
    return vim.api.nvim_call_function("minpac#status", {})
end


function M.packadd(name)
    vim.api.nvim_command("packadd " .. name)
end


function M.packaddall()
    vim.api.nvim_command("packloadall")
end


return M
