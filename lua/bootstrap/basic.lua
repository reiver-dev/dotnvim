--- Trivial helpers
--

local M = {}

local is_win = vim.fn.has("win32") == 1


--- Read file contents entrely as text
--- @param path string
--- @return string
--- @nodiscard
function M.slurp(path)
    local stream = assert(io.open(path, "r"))
    local ok, result = pcall(stream.read, stream, "*all")
    stream:close()
    if not ok then
        error(result)
    end
    return result
end

--- Write text to file, create parent directory
--- @param path string
--- @param data string
function M.spew(path, data)
    local stream, err, errno = io.open(path, "wb")

    if not stream then
        if errno == 2 then
            vim.fn.mkdir(vim.fn.fnamemodify(path, ":p:h"), "p", 448)
            stream, err = io.open(path, "wb")
        else
            error(err)
        end
    end

    local ok, result = pcall(stream.write, stream, data)

    stream:close()

    if not ok then
        error(result)
    end
end


--- Remove directory using shell command
--- @param path string
--- @see os.execute
local rmdir
if is_win then
    rmdir = function(path)
        local stat = vim.loop.fs_stat(path)
        if stat and stat.type == "directory" then
            local p = string.gsub(path, "/", "\\")
            os.execute("rmdir /S /Q " .. vim.fn.fnameescape(p))
        end
    end
else
    rmdir = function(path)
        local stat = vim.loop.fs_stat(path)
        if stat and stat.type == "directory" then
            os.execute("rm -rf " .. vim.fn.fnameescape(path))
        end
    end
end
M.rmdir = rmdir


--- Make directory with parents using shell command
--- @param path string
local mkdir
if is_win then
    mkdir = function(path)
        local stat = vim.loop.fs_stat(path)
        if stat ~= nil then
            if stat.type ~= "directory" then
                error("Path is not directory: " .. path)
            end
        else
            vim.fn.mkdir(string.gsub(path, "/", "\\"), "p", 448)
        end
    end
else
    mkdir = function(path)
        local stat = vim.loop.fs_stat(path)
        if stat ~= nil then
            if stat.type ~= "directory" then
                error("Path is not directory: " .. path)
            end
        else
            vim.fn.mkdir(path, "p", 448)
        end
    end
end
M.mkdir = mkdir


--- Check if path is directory
--- @param path string
--- @return boolean
--- @nodiscard
function M.is_dir(path)
    local stat = vim.loop.fs_stat(path)
    return stat and stat.mode and bit.band(stat.mode, 0x4000) ~= 0
end


--- Find one of paths in runtime
--- @param paths string[]
--- @return string|nil
--- @nodiscard
local runtime
if vim.api.nvim__get_runtime then
    runtime = function(paths)
        return vim.api.nvim__get_runtime(paths, false, {is_lua = false})[1]
    end
else
    runtime = function(paths)
        local get = vim.api.nvim_get_runtime_file
        for _, p in ipairs(paths) do
            local found = get(p, false)[1]
            if found then
                return found
            end
        end
	return nil
    end
end
M.runtime = runtime


return M

--- basic.lua ends here
