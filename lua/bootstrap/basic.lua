--- Trivial helpers
--

local M = {}

local is_win = vim.fn.has("win32") == 1


local function fserror(fname, err)
    return error(string.format("At file `%s`: %s", fname, err), 1)
end


function M.slurp(path)
    local stream = assert(io.open(path, "r"))
    local ok, result = pcall(stream.read, stream, "*all")
    stream:close()
    if not ok then
        error(result)
    end
    return result
end


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

    return result
end


local function chdir_command()
    if vim.fn.haslocaldir() == 1 then
        return "lcd"
    elseif vim.fn.haslocaldir(-1, 0) == 1 then
        return "tcd"
    else
        return "cd"
    end
end


function M.rmdir(path)
    local stat = vim.loop.fs_stat(path)
    if stat and stat.type == "directory" then
        if is_win then
            local p = string.gsub(path, "/", "\\")
            p = vim.fn.fnameescape(p)
            os.execute("rmdir /S /Q " .. p)
        else
            local p = vim.fn.fnameescape(path)
            os.execute("rm -rf " .. p)
        end
    end
end


function M.mkdir(path)
    local stat, err, code = vim.loop.fs_stat(path)
    if stat ~= nil then
        if stat.type ~= "directory" then
            error("Path is not directory: " .. path)
        end
    elseif is_win then
        vim.fn.mkdir(string.gsub(path, "/", "\\"), "p", 448)
    else
        vim.fn.mkdir(path, "p", 448)
    end
end


function M.with_dir(dir, func)
    local chdir = chdir_command()
    local cwd = vim.fn.getcwd()
    local t = "silent %s %s"
    vim.cmd(t:format(chdir, vim.fn.fnameescape(dir)))
    local ok, res = xpcall(func, debug.traceback)
    vim.cmd(t:format(chdir, vim.fn.fnameescape(cwd)))
    if not ok then
        error(res)
    end
    return res
end


function M.is_dir(path)
    local stat = vim.loop.fs_stat(path)
    return stat and stat.mode and bit.band(stat.mode, 0x4000) ~= 0
end


if vim.api.nvim__get_runtime then
    function M.runtime(paths)
        return vim.api.nvim__get_runtime(paths, false, {is_lua = false})[1]
    end
else
    function M.runtime(paths)
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


return M

--- basic.lua ends here
