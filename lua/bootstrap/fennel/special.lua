--- Fennel compiler special forms
--

local fennel = "aniseed.deps.fennel"

local M = {}

local function filename_to_module(path)
    path = string.gsub(path, root, "")
    path = string.gsub(path, "(.*)%.fnl$", "%1")
    path = string.gsub(path, "/", ".")
    return path
end


function M.currentfile(ast, scope, parent, opts)
    if nil ~= ast.filename then
        return string.format("%q", ast.filename)
    else
        return "\"<unknown>\""
    end
end


function M.currentmodule(ast, scope, parent, opts)
    if nil ~= ast.filename then
        return string.format("%q", (filename_to_module(ast.filename)))
    else
        return "\"<unknown>\""
    end
end


function M.debugscope(ast, scope, parent, opts)
    return string.format("%q", view(scope))
end


function M.debugast(ast, scope, parent, opts)
    return string.format("%q", view(ast))
end


function M.debugparent(ast, scope, parent, opts)
    return string.format("%q", view(parent))
end


function M.debugopts(ast, scope, parent, opts)
    return string.format("%q", view(opts))
end


function M.debugall(ast, scope, parent, opts)
    local data = {
        ast = ast,
        scope = scope,
        parent = parent,
        opts = opts
    }
    return string.format("%q", view(data))
end


function M.modcall(ast, scope, parent, opts)
    if #ast < 2 then
        error(string.format("Must have >3 args: %s", vim.inspect(ast)))
    end

    local result = fennel.list()
    local mm = {string.match(ast[2], "(.*)/(.*)")}
    if #mm > 0 then
        result[1] = fennel.list(
            fennel.sym("."),
            fennel.list(
                fennel.sym("require"),
                mm[1]
            ),
            mm[2]
        )
    else
        result[1] = ast[2]
    end

    local i = 2
    local a = 3
    local len = #ast
    while a <= len do
        result[i] = ast[a]
        i = i + 1
        a = a + 1
        len = len - 1
    end

    return fennel.compile1(result, scope, parent, opts)
end


return M

--- specials.lua ends here
