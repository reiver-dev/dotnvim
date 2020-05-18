--- Command operations
--


local trampouline = require "bootstrap.interop.trampouline"


local NARGS_NONE = "0"
local NARGS_ONE = "1"
local NARGS_ANY = "*"
local NARGS_OPTIONAL = "?"
local NARGS_MANY = "+"

local VALID_NARGS = {
    [0] = NARGS_NONE,
    ["0"] = NARGS_NONE,
    [1] = NARGS_ONE,
    ["1"] = NARGS_ONE,
    [NARGS_ANY] = NARGS_ANY,
    [NARGS_MANY] = NARGS_MANY,
    [NARGS_OPTIONAL] = NARGS_OPTIONAL
}

local function nargs_spec(arg)
    if arg == nil then
        return NARGS_NONE
    end

    local value = VALID_NARGS[arg]
    if value ~= nil then
        return value
    end

    error(string.format("expected nargs spec, got %s", arg))
end


local RANGE_NONE = nil
local RANGE_CURRENT = ""
local RANGE_FILE = "%"
local RANGE_N = "N"


local function range_spec(arg)
    if arg == RANGE_NONE or arg == RANGE_CURRENT or arg == RANGE_FILE then
        return arg, 0
    end

    if type(arg) == "number"  then
        return RANGE_N, arg
    end

    error(string.format("expected range spec, got %s", arg))
end


local function count_spec(arg)
    if arg == nil or type(arg) == "number" then
        return arg
    end
    error(string.format("expected count spec, got %s", arg))
end


local ADDR_NONE = nil
local ADDR_LINES = "lines"
local ADDR_ARGUMENTS = "arguments"
local ADDR_BUFFERS = "buffers"
local ADDR_LOADEDBUFFERS = "loaded_buffers"
local ADDR_WINDOWS = "windows"
local ADDR_TABS = "tabs"
local ADDR_OTHER = "other"


local VALID_ADDR = {
    [ADDR_LINES] = true,
    [ADDR_ARGUMENTS] = true,
    [ADDR_BUFFERS] = true,
    [ADDR_LOADEDBUFFERS] = true,
    [ADDR_WINDOWS] = true,
    [ADDR_TABS] = true,
    [ADDR_OTHER] = true,
}

local function addr_spec(arg)
    if arg == ADDR_NONE or VALID_ADDR[arg] ~= nil then
        return arg
    end
    error(string.format("expected addr spec, got %s", arg))
end


local function bool_spec(arg)
    if arg == nil then
        return false
    end

    if type(arg) == "boolean" then
        return arg
    end

    if type(arg) == "number" then
        return arg ~= 0
    end

    if #arg > 0 then
        return arg
    end
end


local function string_spec(arg)
    if arg == nil then
        return ""
    end
    if type(arg) == "string" then
        return arg
    end
    error("expected string, got %s", type(arg))
end


local function list_spec(arg)
    if nil == arg then
        return {}
    end

    if type(arg) == "table" then
	if #arg > 0 then
            return table
	end
	return {}
    end

    return {arg}
end


local REGISTER_NONE = ""
local REGISTER_DEL = ":del"
local REGISTER_PUT = ":put"
local REGISTER_YANK = ":yank"


local function register_spec(arg)
    if (arg == nil or arg == REGISTER_NONE or arg == REGISTER_DEL
        or arg == REGISTER_PUT or arg == REGISTER_YANK) then
        return arg
    end
    error("expected register spec, got %s", arg)
end


local MODS = {
    [":aboveleft"] = true,
    [":belowright"] = true,
    [":botright"] = true,
    [":browse"] = true,
    [":confirm"] = true,
    [":hide"] = true,
    [":keepalt"] = true,
    [":keepjumps"] = true,
    [":keepmarks"] = true,
    [":keeppatterns"] = true,
    [":leftabove"] = true,
    [":lockmarks"] = true,
    [":noswapfile"] = true,
    [":rightbelow"] = true,
    [":silent"] = true,
    [":tab"] = true,
    [":topleft"] = true,
    [":verbose"] = true,
    [":vertical"] = true,
}


local function mods_spec(arg)
    if arg == nil or MODS[arg] ~= true then
        return arg
    end
    error("expected mod spec, got %s", arg)
end

local function range_text(range, count)
    if range == RANGE_NONE then
        return nil
    end

    if range == RANGE_CURRENT and "-range" then
        return "-range"
    end

    if range == RANGE_FILE then
        return "-range=%"
    end

    if range == RANGE_N then
        return string.format("-range=%d", count)
    end

    error(string.format("invalid range spec: %s", range))
end


local function command(opts)
    local name = opts["name"]
    local modname = opts["modname"]
    local funcname = opts["funcname"]

    vim.validate({
        name = {name, 's'},
        modname = {modname, 's'},
        funcname = {funcname, 's'},
    })

    local nargs = nargs_spec(opts["nargs"])
    local range, rcount = range_spec(opts["range"])
    local count = count_spec(opts["count"])
    local addr = addr_spec(opts["addr"])
    local complete = list_spec(opts["complete"])
    local bang = bool_spec(opts["bang"])
    local bar = bool_spec(opts["bar"])
    local buffer = bool_spec(opts["buffer"])
    local register = register_spec(opts["register"])
    local mods = mods_spec(opts["mods"])

    local definition = {}
    local pos = 1

    local add = function (value)
        if value ~= nil then
            definition[pos] = value
            pos = pos + 1
        end
    end

    add("command!")
    add(nargs and string.format("-nargs=%s", nargs) or nil)
    add(range_text(range, rcount))
    add(count and string.format("-count=%d", count) or nil)
    add(addr and string.format("-addr=%s", addr) or nil)
    add(bang and "-bang" or nil)
    add(bar and "-bar" or nil)
    add(buffer and "-buffer" or nil)
    add(register and string.format("-register=%s", register) or nil)
    add(name)
    add("call")
    add(trampouline.command(modname, funcname))

    return table.concat(definition, " ")
end


return {
    NARGS_NONE = NARGS_NONE,
    NARGS_ONE = NARGS_ONE,
    NARGS_ANY = NARGS_ANY,
    NARGS_OPTIONAL = NARGS_OPTIONAL,
    NARGS_MANY = NARGS_MANY,

    ADDR_LINES = ADDR_LINES,
    ADDR_ARGUMENTS = ADDR_ARGUMENTS,
    ADDR_BUFFERS = ADDR_BUFFERS,
    ADDR_LOADEDBUFFERS = ADDR_LOADEDBUFFERS,
    ADDR_WINDOWS = ADDR_WINDOWS,
    ADDR_TABS = ADDR_TABS,
    ADDR_OTHER = ADDR_OTHER,

    BANG = "!",
    REGISTER_NONE = REGISTER_NONE,
    REGISTER_DEL = REGISTER_DEL,
    REGISTER_PUT = REGISTER_PUT,
    REGISTER_YANK = REGISTER_YANK,

    make = command
}

--- command.lua ends here
