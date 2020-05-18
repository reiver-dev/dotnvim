--- Util lua functions
--

local function haslocaldir()
    return vim.fn.haslocaldir()
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


local function chdir(path)
    local pwd = vim.fn.getcwd()
    vim.cmd(chdir_command() .. " " .. vim.fn.fnameescape(path))
    return pwd
end


local function with_directory(path, func)
    local cmd = chdir_command() 
    local pwd = vim.fn.getcwd()

    vim.cmd(cmd .. " " .. vim.fn.fnameescape(path))
    local ok, res = pcall(func)
    vim.cmd(cmd .. " " .. vim.fn.fnameescape(pwd))

    if not ok then
        error(res)
    end

    return res
end


local function callerror(func, err)
    return string.format("Error (%s): %s",
        debug.getinfo(func).short_src,
	err)
end


local function compose(...)
    local left = select('#', ...)
    local functions = {...}  
    local function apply(i, ...)
        if i == 1 then
            return functions[1]()
        else
            return apply(i - 1, functions[i](...))
        end
    end
    return function(...)
        return reduce(left, ...)
    end
end



return {
    callerror = callerror,
    chdir = chdir,
    with_directory = with_directory,
    compose = compose,
}

--- util.lua ends here
