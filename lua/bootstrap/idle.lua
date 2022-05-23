--- Idle timer detached from CursorHold'I event

local timer = vim.loop.new_timer()
local timeout = 250
local pcall, ipairs = pcall, ipairs


local hook_handlers = {
    always = {
        handlers = {},
        sequence = {}
    },
    once = {
        handlers = {},
        sequence = {}
    }
}


local function call_hook(is_insert)
    for _, hook in ipairs(hook_handlers.once.sequence) do
        hook(is_insert)
    end
    hook_handlers.once.handlers = {}
    hook_handlers.once.sequence = {}
    for _, hook in ipairs(hook_handlers.always.sequence) do
        hook(is_insert)
    end
end


local forward_autocmd
do
    local eventignore = vim.opt.eventignore
    local nvim_exec_autocmds = vim.api.nvim_exec_autocmds
    local opts = { modeline = false }
    forward_autocmd = function(name)
        eventignore:remove(name)
        nvim_exec_autocmds(name, opts)
        eventignore:append(name)
    end
end


local on_timer_normal = vim.schedule_wrap(function()
    pcall(call_hook, false)
    forward_autocmd("CursorHold")
end)


local on_timer_insert = vim.schedule_wrap(function()
    pcall(call_hook, true)
    forward_autocmd("CursorHoldI")
end)


local not_recording
do
    local empty = {}
    local call = vim.call
    not_recording = function()
        return call("reg_recording", empty) == ""
    end
end


local mode_normal
do
    local nvim_get_mode = vim.api.nvim_get_mode
    local sub = string.sub
    mode_normal = function()
        return sub(nvim_get_mode().mode, 1, 1) == "n"
    end
end


local function on_idle_break(is_insert)
    timer:stop()
    if not_recording() and (is_insert or mode_normal()) then
        local cb = is_insert and on_timer_insert or on_timer_normal
        timer:start(timeout, 0, cb)
    end
end


--- Add idle hook
---@param name string
---@param func fun(is_insert: boolean)
---@param once? boolean
local function hook(name, func, once)
    local h
    if once then
        h = hook_handlers.once
    else
        h = hook_handlers.always
    end
    local place = h.handlers[name]
    if place == nil then
        place = #h.sequence + 1
        h.handlers[name] = place
    end
    h.sequence[place] = func
end


--- Initialize idle hook and CursorHold'I passing
local function setup()
    vim.opt.eventignore:append({ "CursorHold", "CursorHoldI" })

    local ag = vim.api.nvim_create_augroup("idle_timer", { clear = true, })

    vim.api.nvim_create_autocmd("CursorHold", {
        group = ag,
        desc = "bootstrap.idle::on_idle_break(is_insert: false)",
        callback = function()
            on_idle_break(false)
        end
    })

    vim.api.nvim_create_autocmd("CursorHoldI", {
        group = ag,
        desc = "bootstrap.idle::on_idle_break(is_insert: true)",
        callback = function()
            on_idle_break(true)
        end
    })
end


return {
    setup = setup,
    hook = hook
}
