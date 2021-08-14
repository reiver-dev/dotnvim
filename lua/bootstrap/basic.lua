--- Trivial helpers
--

local M = {}

local uv = vim.loop
local is_win
local is_posix
do
    local osdetect = require("bootstrap.osdetect")
    is_win = osdetect.is_win
    is_posix = osdetect.is_posix
end


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


function M.uvslurp(path)
    local fd, stat, data, err

    fd, err = uv.fs_open(path, "r", 438)
    if fd == nil then
        error(fserror(path, err))
    end

    stat, err = uv.fs_fstat(fd)
    if stat == nil then
        uv.fs_close(fd)
        error(fserror(path, err))
    end

    data, err = uv.fs_read(fd, stat.size, 0)
    if data == nil then
        error(fserror(path, err))
    end

    if uv.fs_close(fd) == nil then
        error(fserror(path, err))
    end

    return data
end


function M.spew(path, data)
    local stream, err, errno = io.open(path, "wb")

    if not stream then
        if errno == 2 then
            local dir, name = M.splitpath(path)
            M.mkdir(dir)
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
    if vim.fn.haslocaldir() then
        return "lcd"
    elseif vim.fn.haslocaldir(-1, 0) then
        return "tcd"
    else
        return "cd"
    end
end


function M.rmdir(path)
    local stat = uv.fs_stat(path)
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


local function is_dir(path)
    local stat = uv.fs_stat(path)
    return stat and stat.mode and bit.band(stat.mode, 0x4000) ~= 0
end


local function rcut_posix(path, stop)
    local i = stop or #path
    local at = string.byte

    while 0 < i and at(path, i) == 47 do
        i = i - 1
    end

    while 0 < i and at(path, i) ~= 47 do
        i = i - 1
    end

    return i
end


local function rtrim_posix(path, stop)
    local i = stop or #path
    local at = string.byte
    while 0 < i and at(path, i) == 47 do
        i = i - 1
    end
    return i
end


local function ftrim_posix(path, start)
    local i = start or 1
    local e = #path
    local at = string.byte
    while i < e and at(path, i) == 47 do
        i = i + 1
    end
    return i
end


local function splitpath_posix(path)
    local sub = string.sub
    local i = ftrim_posix(path)
    local pos = rcut_posix(path)
    if pos > i then
        return sub(path, 1, pos), sub(path, pos)
    end
    if i == 2 then
        return "//", ""
    elseif i > 0 then
        return "/", ""
    else
        return ".", ""
    end
end


local function rcut_win(path, stop)
    local i = stop or #path
    local at = string.byte

    while 0 < i and (at(path, i) == 47 or at(path, i) == 92) do
        i = i - 1
    end

    while 0 < i and not (at(path, i) == 47 or at(path, i) == 92) do
        i = i - 1
    end

    return i
end


local function rtrim_win(path, stop)
    local i = stop or #path
    local at = string.byte
    while 0 < i and (at(path, i) == 47 or at(path, i) == 92) do
        i = i - 1
    end
    return i
end


local function ftrim_win(path, start)
    local i = start or 1
    local e = #path
    local at = string.byte
    while i <= e and (at(path, i) == 47 or at(path, i) == 92) do
        i = i + 1
    end
    return i
end


local function splitpath_win(path)
    local sub = string.sub
    local match = string.match

    local root = (match(path, "^[a-zA-Z]:[\\/]*") or
                  match(path, "^[\\/][\\/]+[^\\/]+[\\/]+[^\\/]+[\\/]*"))

    local tail_begin
    if root ~= nil then
        tail_begin = #root
    else
        tail_begin = 0
    end

    local tail_end = rcut_win(path)
    if tail_begin < tail_end then
        return sub(path, 1, tail_end), sub(path, tail_end)
    end

    return root or ".", ""
end


local splitpath
if is_posix then
    splitpath = splitpath_posix
else
    splitpath = splitpath_win
end
M.splitpath = splitpath


function M.mkdir(path)
    local numstack = 1
    local stack = {path}

    do
        local head, tail = splitpath(path)
        while tail ~= "" do
            numstack = numstack + 1
            stack[numstack] = head
            head, tail = splitpath(head)
        end
    end

    while numstack > 0 do
        local name = stack[numstack]
        local success, err, code = uv.fs_mkdir(name, 448)
        if success or is_dir(name) then
            stack[numstack] = nil
            numstack = numstack - 1
        else
            error(fserror(name, err))
        end
    end
end

return M

--- basic.lua ends here
