local exec = vim.cmd

local eventignore = vim.opt.eventignore

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


local on_timer_normal = vim.schedule_wrap(function()
    pcall(call_hook, false)
    eventignore:remove "CursorHold"
    exec "doautocmd <nomodeline> CursorHold"
    eventignore:append "CursorHold"
end)


local on_timer_insert = vim.schedule_wrap(function()
    pcall(call_hook, true)
    eventignore:remove "CursorHoldI"
    exec "doautocmd <nomodeline> CursorHoldI"
    eventignore:append "CursorHoldI"
end)


local not_recording
do
    local empty = {}
    local nvim_call_function = vim.api.nvim_call_function
    not_recording = function()
        return nvim_call_function("reg_recording", empty) == ""
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


local COMMAND = [[
    augroup idle_timer
        autocmd!
        autocmd CursorMoved * lua __on_idle_break(false)
        autocmd CursorMovedI * lua __on_idle_break(true)
    augroup END
]]


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
    eventignore:append({ "CursorHold", "CursorHoldI" })
    exec(COMMAND)
    _G.__on_idle_break = on_idle_break
end


return {
    setup = setup,
    hook = hook
}
