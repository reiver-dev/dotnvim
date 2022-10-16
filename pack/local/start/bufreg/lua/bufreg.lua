--- Buffer registry

local current_buffer = vim.api.nvim_get_current_buf
local setbufvar = vim.api.nvim_buf_set_var
local getbufvar = vim.api.nvim_buf_get_var
local delbufvar = vim.api.nvim_buf_del_var

--- @class Registry
--- @field state table<integer, table<string, any>>
--- @field mapping table<integer, integer>
--- @field free_ids integer[]
--- @field top_id integer
--- @field varname string
--- @field funcname string

--- @param varname string
--- @param funcname string
--- @return Registry
local function new_registry(varname, funcname)
    return {
        state = {},
        mapping = {},
        free_ids = {},
        top_id = 0,
        varname = varname,
    }
end


--- @param reg Registry
--- @param front_id integer
local function claim_id(reg, front_id)
    local back_id = next(reg.free_ids)
    if back_id then
        reg.free_ids[back_id] = nil
    else
        back_id = reg.top_id + 1
        reg.top_id = back_id
    end
    reg.mapping[front_id] = back_id
    return back_id
end


--- @param reg Registry
--- @param front_id integer
--- @param back_id integer
local function return_id(reg, front_id, back_id)
    local current_back_id = reg.mapping[front_id]
    if current_back_id == back_id then
        reg.mapping[front_id] = nil
    end
    reg.state[back_id] = nil
    reg.free_ids[back_id] = true
end


--- @param reg Registry
--- @param front_id integer
--- @param back_id integer
--- @return userdata Anchor
local function make_anchor(reg, front_id, back_id)
    local proxy = newproxy(true)
    local metatable = getmetatable(proxy)
    metatable.__gc = function() return_id(reg, front_id, back_id) end
    return proxy
end


--- @param reg Registry
--- @param bufnr integer
--- @return integer State id
local function ensure_state(reg, bufnr)
    local exists, func = pcall(getbufvar, bufnr, reg.varname)
    if exists then
        return func()
    end

    local id = claim_id(reg, bufnr)

    reg.state[id] = {
        id = id,
        bufnr = bufnr,
    }

    local wrap = {
        id = id,
        anchor = make_anchor(reg, bufnr, id)
    }

    setbufvar(bufnr, reg.varname, function() return wrap.id end)

    return id
end


--- @param reg Registry
--- @param bufnr integer
local function delete_buffer_state(reg, bufnr)
    delbufvar(bufnr, reg.varname)
end

--- Validate buffer handle value, query current buffer handle
--- if nil or not positive
--- @param bufnr integer|nil
--- @return integer
local function buffer_id(bufnr)
    if bufnr == nil then
        return current_buffer()
    elseif type(bufnr) == "number" then
        if 0 < bufnr then
            return bufnr
        else
            return current_buffer()
        end
    end
    error("BUFNR must be number, got " .. type(bufnr))
end


--- @param map table
--- @param n number
--- @param key any
--- @param ... any
--- @return any
local function set_local_1(map, n, key, ...)
    if n ~= 0 then
        local nested = map[key]
        if not nested then
            nested = {}
            map[key] = nested
        end
        return set_local_1(nested, n - 1, ...)
    end
    local result = ...
    map[key] = result
    return result
end


--- @param map table
--- @param n number
--- @param key any
--- @param ... any
--- @return any
local function get_local_1(map, n, key, ...)
    local nested = map[key]
    if nested and n ~= 0 then
        return get_local_1(nested, n - 1, ...)
    end
    return nested
end


--- @param map table
--- @param n number
--- @param key any
--- @param ... any
--- @return any
local function upd_local_1(map, n, key, ...)
    if n ~= 0 then
        local nested = map[key]
        if not nested then
            nested = {}
            map[key] = nested
        end
        return upd_local_1(nested, n - 1, ...)
    end
    local result = select(1, ...)(map[key])
    map[key] = result
    return result
end


--- @param reg Registry
--- @param bufnr number
--- @param ... any
--- @return any
local function set_local(reg, bufnr, ...)
    local n = select("#", ...)
    if n == 0 then
        return
    end
    bufnr = buffer_id(bufnr)
    local id = reg.mapping[bufnr] or ensure_state(reg, bufnr)
    if id then
        if n == 1 and select(1, ...) == nil then
            return delete_buffer_state(reg, bufnr)
        else
            return set_local_1(reg.state, n - 1, id, ...)
        end
    end
end


--- @param reg Registry
--- @param bufnr number
--- @param ... any
--- @return any
local function get_local(reg, bufnr, ...)
    bufnr = buffer_id(bufnr)
    local id = reg.mapping[bufnr]
    if id then
        local n = select("#", ...)
        return get_local_1(reg.state, n, id, ...)
    end
end


--- @param reg Registry
--- @param bufnr number
--- @param ... any
--- @return any
local function upd_local(reg, bufnr, ...)
    local n = select("#", ...)
    if n < 2 then
        return
    end
    if select(1, ...) == nil then
        error("First key must not be nil")
    end
    bufnr = buffer_id(bufnr)
    local id = reg.mapping[bufnr] or ensure_state(reg, bufnr)
    if id then
        return upd_local_1(reg.state, n - 1, id, ...)
    end
end


--- Associcate value with buffer state.
--- @param bufnr number|nil Buffer handle
--- @param ... any
--- @return any Last value of vararg
local function setlocal(bufnr, ...)
    return set_local(_G._BUFFER_REGISTRY(), bufnr, ...)
end

--- @type fun(): Registry
_BUFFER_REGISTRY = nil

--- Get current associated value in buffer state.
--- @param bufnr number|nil
--- @param ... any
--- @return any Associated value or nil
local function getlocal(bufnr, ...)
    return get_local(_BUFFER_REGISTRY(), bufnr, ...)
end


--- Update current associated value in buffer state.
--- @param bufnr number|nil
--- @param ... any Keys to find the state, last elemet must be function
--- @return any Value returned by function in vararg
local function updlocal(bufnr, ...)
    return upd_local(_BUFFER_REGISTRY(), bufnr, ...)
end


local function autocmd_new(opts)
    ensure_state(_BUFFER_REGISTRY(), opts.buf)
end


--- @class Options
--- @field varname string

--- @param opts Options
local function setup(opts)
    vim.api.nvim_create_autocmd(
        { "VimEnter", "BufNew", "BufNewFile", "BufReadPre" },
        {
            group = vim.api.nvim_create_augroup("bufreg", { clear = false }),
            callback = autocmd_new,
        }
    )

    if not _BUFFER_REGISTRY then
        local vndefault = '__buffer_registry_state_ref_holder__'
        local varname = opts and opts.varname or vndefault
        local reg = new_registry(varname)
        _BUFFER_REGISTRY = function()
            return reg
        end
    end

    local registry = _BUFFER_REGISTRY()

    _G.SETLOCAL = function(bufnr, ...)
        return set_local(registry, bufnr, ...)
    end

    _G.GETLOCAL = function(bufnr, ...)
        return get_local(registry, bufnr, ...)
    end

    _G.UPDLOCAL = function(bufnr, ...)
        return upd_local(registry, bufnr, ...)
    end
end


return {
    setup = setup,
    setlocal = setlocal,
    getlocal = getlocal,
    updlocal = updlocal,
}


--- bufreg.lua ends here
