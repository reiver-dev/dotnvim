--- One time callback
--

local counter = 0
local callbacks = {}
local validate = vim.validate


local function makename()
    counter = counter + 1
    return string.format("__callback__%d", counter)
end


local function makescript(name)
    return string.format("lua require(\"bootstrap.callback\").call(%q)", name)
end


local function make(func)
    validate {
        func = {func, "f"}
    }
    local name = makename()
    callbacks[name] = func
    return makescript(name)
end


local function call(name)
    validate {
        name = {name, "s"}
    }
    local func = callbacks[name]
    if nil ~= func then
        callbacks[name] = nil
        func()
    else
        error(string.format("Invalid callback: %q", name))
    end
end


return {
    make = make,
    call = call
}
