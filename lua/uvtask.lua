local task = require "task"
local uv = vim.uv
local anchor = assert(uv.new_idle())

local root_scheduler = task.new_scheduler()

local anchored = false

local scheduler_uv_callback

local function suspend()
    if anchored then
        anchor:stop()
        anchored = false
    end
end

local function schedule()
    if not anchored then
        anchor:start(scheduler_uv_callback)
        anchored = true
    end
end

root_scheduler:fn("step", function()
    if root_scheduler:nready() == 0 then
        suspend()
    elseif not anchored then
        schedule()
    end
end)

root_scheduler:fn("spawn", function()
    schedule()
end)

scheduler_uv_callback = function()
    root_scheduler:step(0)
end


--- @param t task
--- @return fun(...)
local function resuming(t)
    return function(...)
        if not t:iscancelled() then
            t:resume(...)
        end
    end
end


--- @async
local function main()
    if not vim.in_fast_event() then
        return
    end
    local t = task.current()
    if not t then
        return
    end
    suspend()
    vim.schedule(resuming(t))
    t:block()
end


--- @param func async fun(...)
--- @param ... any
--- @return task
local function spawn(func, ...)
    return root_scheduler:spawn(func, ...)
end


--- @async
--- @param timeout number
local function sleep(timeout)
    if not task.isrunning() then
        uv.sleep(timeout)
    end
    local sig = task.signal()
    local timer = assert(uv.new_timer())
    timer:start(timeout, 0, function()
        timer:stop()
        timer:close()
        sig:post()
    end)
    sig:wait()
end


return {
    main = main,
    resuming = resuming,
    spawn = spawn,
    sleep = sleep,
}
