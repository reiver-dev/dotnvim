--- Trivial helpers
--

local M = {}


function M.slurp(path)
    local stream = assert(io.open(path, "rb"))
    local ok, result = pcall(stream.read, stream, "*all")
    stream:close()
    if not ok then
        error(result)
    end
    return result
end


function M.spew(path, data)
    vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
    local stream = assert(io.open(path, "wb"))
    local ok, result = pcall(stream.write, stream, data)
    stream:close()
    if not ok then
        error(result)
    end
    return result
end


local function chdir_command()
    if vim.fn.haslocaldir() then
        return "lcd"
    elseif vim.fn.haslocaldir(-1, 0) then
        return "tcd"
    else
        return "cd"
    end
end


function M.rmdir(path)
    local stat = vim.loop.fs_stat(path)
    if stat and stat.type == "directory" then
        if vim.fn.has("win32") == 1 then
            local p = string.gsub(path, "/", "\\")
            p = vim.fn.fnameescape(p)
            os.execute("rmdir /S /Q " .. p)
        else 
            local p = vim.fn.fnameescape(path)
            os.execute("rm -rf " .. p)
        end
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


return M

--- basic.lua ends here
