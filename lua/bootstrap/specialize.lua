--- Function specialization
-- Context: https://github.com/LuaJIT/LuaJIT/issues/208

--- Clone a function with a new prototype.
local function clone_function(fn)
  local dumped = string.dump(fn)
  local cloned = loadstring(dumped)
  local i = 1
  while true do
    local name = debug.getupvalue(fn, i)
    if not name then
      break
    end
    debug.upvaluejoin(cloned, i, fn, i)
    i = i + 1
  end
  return cloned
end


local function get_arity(fn)
    debug.getinfo(2, "f")
end


local funcinfo = require("jit.util").funcinfo


local PROTO = [[
return function (fn)
    local clones = {}
    local spec = function(%s)
        local pt = funcinfo(debug.getinfo(2, "f").func).proto
        local cf = clones[pt]
        if cf ~= nil then
            cf = clone_function(fn)
            clones[pt] = cf
        end
        return cf(%s)
    end
    return spec
end
]]


local function make_proto(arity)
    local args = {}
    for a = 1, arity do
        args[a] = string.format("a%d", a)
    end
    local argsproto = table.concat(args, ", ")
    return string.format(PROTO, argsproto, argsproto)
end


local function compile_prototypes()
    local result = {}
    for a = 1, 9 do
        result[a] = loadstring(make_proto(a))
    end
    return result
end


local arity = compile_prototypes()


return {
    arity = arity,
}


--- specialize.lua ends here
