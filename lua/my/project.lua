local fw = require "my.fswalk"
local p = require "my.promise"
local b = require "bufreg"

local interesting_files = {".projectile", ".lnvim.fnl"}
local interesting_directories = {".git", ".hg"}

local function getbufvar(bufnr, name)
    local ok, res = pcall(vim.api.nvim_buf_get_var, bufnr or 0, name)
    if ok then return res end
    return ""
end

local function setbufvar(bufnr, name, value)
    vim.api.nvim_buf_set_var(bufnr or 0, name, value)
end

local function project_root(bufnr)
    local pr = b.getlocal(bufnr, "project", "root")
    if pr then return pr end
    return getbufvar(bufnr, "projectile")
end

local function find_nearest_provider(...)
    local provider

    local shortest_path
    local longest_path

    local shortest_len = 1e10
    local longest_len = 0

    for _, providers in ipairs({...}) do
        for name, entries in pairs(providers) do
            local loc = entries[1]
            local loclen = loc and loc:len() or 0
            if longest_len < loclen then
                longest_len = loclen
                longest_path = loc
                provider = name
            end
            if shortest_len >= loclen then
                shortest_len = loclen
                shortest_path = loc
            end
        end
    end

    return provider, longest_path, shortest_path
end

local function fire_user_event(bufnr, event)
  if vim.fn.exists(string.format("#User#%s", event)) then
      local cmd = string.format("doautocmd <nomodeline> User %s", event)
      vim.api.nvim_buf_call(bufnr, function() vim.cmd(cmd) end)
  end
end

local function fire_project_updated(bufnr)
    fire_user_event(bufnr, "Projectile")
end

local function do_project_search(bufnr, path)
    local files, dirs = fw["async-gather"](path, interesting_files, interesting_directories)
    local data = {files = files, dirs = dirs}
    local lnvim = files[".lnvim.fnl"]
    if lnvim then
        b.setlocal("bufnr", "dir-local", lnvim)
        files[".lnvim.fnl"] = nil
    end
    b.setlocal(bufnr, "project", "triggers", data)
    local found_provider, found_path = find_nearest_provider(files, dirs)
    b.setlocal(bufnr, "project", "root", found_path)
    b.setlocal(bufnr, "project", "provider", found_provider)
    vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(bufnr) then
            return
        end
        setbufvar(bufnr, "projectile", found_path)
        setbufvar(bufnr, "asyncrun_root", path)
        setbufvar(bufnr, "projectile_provider", found_provider)
        setbufvar(bufnr, "projectile_locs", data)
        fire_project_updated(bufnr)
    end)
end

local function defer_project_search(bufnr, path)
    p.new(do_project_search, bufnr, path)
end

local function on_directory_changed(bufnr, directory)
    defer_project_search(bufnr, directory)
end

local function setup()
    require"my.directory".add_hook("my.project", on_directory_changed)
end

return {
    setup = setup,
    project_root = project_root,
    ["project-root"] = project_root,
}
