--- vim-packager module
--

local M = {}

local function gather(source, fields)
    if nil == source  or nil == next(source) then
        return nil
    end

    local dest = {}
    for name, handler in pairs(fields) do
        local v = source[name]   
        if v ~= nil then
            if handler == true then
                dest[name] = v
            else
                dest[name] = handler(v)
            end
        end
    end

    if nil ~= next(dest) then
        return dest
    end

    return nil
end


local function to_set(opts)
    local res = {}
    for _, v in ipairs(opts) do
        res[v] = true 
    end 
    return res
end


local function apply(name, args, toeval)
    if args == nil or next(args) == nil then
        return vim.fn[name]()
    end
    if toeval == nil or next(toeval) == nil then
        return vim.fn[name](unpack(args))
    end
    return vim.api.nvim_call_function('Apply', {name, toeval, args})
end


local INIT_FIELDS = to_set{"depth", "jobs", "dir", "window_cmd",
                           "default_plugin_type", "disable_default_mappings"}


local ADD_FIELDS = to_set{"name", "type", "branch", "tag",
                          "rtp", "commit", "do", "frozen"}

local LOCAL_FIELDS = to_set{"name", "type", "do", "frozen"}


local INSTALL_FIELDS = to_set{"on_finish"}


local UPDATE_FIELDS = to_set{"on_finish", "force_hooks"}


function M.init(opts)
    apply("packager#init", { gather(opts, INIT_FIELDS) })
end


function M.add(url, opts)
    local arg = { url, gather(opts, ADD_FIELDS) }
    return apply("packager#add", arg)
end


function M.localpkg(path, opts)
    local arg = { path, gather(opts, LOCAL_FIELDS) }
    return apply("packager#local", arg)
end


function M.install(opts)
    local arg = { gather(opts, INSTALL_FIELDS) }
    return apply("packager#install", arg)
end


function M.updateall(opts)
    return apply("packager#update", { gather(opts, UPDATE_FIELDS) })
end


function M.status()
    return vim.fn['packager#status']()
end


function M.clean()
    return vim.fn['packager#clean']()
end


function M.installed(name)
    local pkg = vim.fn['packager#plugin'](name)
    return pkg ~= nil and pkg.installed == 1
end

function M.plugin(name)
    return vim.fn['packager#plugin'](name)
end


function M.root()
    local config = vim.api.nvim_call_function("stdpath", {"config"}):gsub("\\", "/")
    return config .. "/pack/packager"
end


function M.download()
    local path = M.root() .. "/opt/packager/"
    local url = "https://github.com/kristijanhusak/vim-packager"
    if vim.api.nvim_call_function("filereadable",
                                  {path .. "LICENSE"}) ~= 1 then
        vim.api.nvim_command(string.format("!git clone %q %q", url, path))
    end
end


function M.setup()
    M.download()
    vim.api.nvim_command("packadd packager")
    M.init()
    M.add("kristijanhusak/vim-packager", { name = "packager", type = "opt" })
end


return M

--- packager.lua ends here
