--- Task scheduler

--- @class (private, exact) task._task_queue
--- @field _tnext self|false
--- @field _tprev self|false

--- @class (private, exact) task._wait_queue
--- @field _wnext self|false
--- @field _wprev self|false

--- @alias task._thread_error_handler fun(thread, string): string
--- @alias task._error_handler fun(string, integer): string
--- @alias task._result_handler fun(boolean?, ...)

--- @class (private) task._hook
--- @field n integer
--- @field c integer
--- @field [integer] function|false
--- @field [function] integer

--- @class (private, exact) task._task_data : task._task_queue, task._wait_queue
--- @field _thread thread
--- @field _nargs integer
--- @field _args any|any[]|false
--- @field _fn task._hook|false
--- @field _status ""|"cancelled"|"done"|"error"|"blocked"
--- @field _shield boolean
--- @field _sched task.scheduler|false
--- @field _q_join task._wait_queue|false
--- @field _errh task._error_handler|false

--- @alias (private) task._reply_id
--- | 1 # Yield
--- | 2 # Cancel
--- | 3 # Block
--- | 4 # BlockShield
--- | 5 # YieldTransfer
--- | 6 # BlockTransfer
--- | 7 # SchedulerCall

--- @class (exact) task : task._task_data
local __task = {}

--- @class (private, exact) task._scheduler_data
--- @field _q_ready task._task_queue
--- @field _q_blocked task._task_queue
--- @field _q_yield task._task_queue
--- @field _running task|false
--- @field _fn {string:task._hook}
--- @field _num_tasks integer
--- @field _num_ready integer
--- @field _tasks {task:true}

--- @class (exact) task.scheduler : task._scheduler_data
local __scheduler = {}

--- @class (private, exact) task._event_data : task._wait_queue
--- @field _state integer
--- @field _args any|any[]|false
--- @field _fn task._hook|false

--- @class (private, exact) task._nonblock_postable : function
--- @operator call():any

--- @alias task.event.state "init"|"posted"|"cancelled"

--- @class (exact) task.event : task._event_data, task._nonblock_postable
local __event = {}

--- @class (exact) task.signal : task._wait_queue, task._nonblock_postable
local __signal = {}

--- @class (private, exact) task._sem_data : task._wait_queue
--- @field _state integer

--- @class task.sem : task._sem_data
local __sem = {}

--- @class (private, exact) task._latch_data : task._wait_queue
--- @field _state integer

--- @class task.latch : task._latch_data
local __latch = {}

--- @class (private, exact) task._chan_data
--- @field _tx task._wait_queue|false
--- @field _rx task._wait_queue|false

--- @class task.chan : task._chan_data
local __chan = {}

--- @class (private, exact) _ring_queue
--- @field r integer
--- @field w integer
--- @field c integer
--- @field n integer
--- @field [integer] any

--- @class (private, exact) _array_linked_queue
--- @field h integer
--- @field t integer
--- @field f integer
--- @field n integer
--- @field [integer] any

--- @class (private, exact) task._bqueue_data
--- @field _q _ring_queue
--- @field _tx task._wait_queue
--- @field _rx task._wait_queue

--- @class (exact) task.bqueue : task._bqueue_data
local __bqueue = {}

--- @class (private, exact) task._bwqueue_data : task._wait_queue
--- @field _q _ring_queue

--- @class (exact) task.wqueue : task._bwqueue_data, task._nonblock_postable
local __bwqueue = {}

--- @class (private, exact) task._uqueue_data : task._wait_queue
--- @field _q _array_linked_queue

--- @class (exact) task.uqueue : task._uqueue_data, task._nonblock_postable
local __uqueue = {}


local co_yield = coroutine.yield
local co_create = coroutine.create
local co_resume = coroutine.resume
local co_status = coroutine.status
local co_running = coroutine.running
--- @diagnostic disable-next-line:deprecated
local co_isyieldable = coroutine.isyieldable
local vararg_unpack = table.unpack or unpack
local select = select
local traceback = debug.traceback
local type = type
local rawget = rawget
local tostring = tostring
local getmetatable = getmetatable


local _pack_dispatch = {
    [0] = function() return 0 end,
    function(a1) return 1, a1 end,
    function(a1, a2)
        if a1 == false then
            return -1, a2
        end
        if a1 == true then
            return -2, a2
        end
        if a1 == nil then
            return -3, a2
        end
        return 2, { a1, a2 }
    end,
    function(a1, a2, a3) return 3, { a1, a2, a3 } end,
    function(a1, a2, a3, a4) return 4, { a1, a2, a3, a4 } end,
}


--- @return integer
--- @return any[]?
local function _pack(...)
    local n = select("#", ...)
    if n == 0 then return 0 end
    if n <= 4 then return _pack_dispatch[n](...) end
    return n, { ... }
end


local _unpack_dispatch = {
    [-3] = function(args) return nil, args end,
    [-2] = function(args) return false, args end,
    [-1] = function(args) return true, args end,
    [0] = function() end,
    function(args) return args end,
    function(args) return args[1], args[2] end,
    function(args) return args[1], args[2], args[3] end,
    function(args) return args[1], args[2], args[3], args[4] end,
}


local function _unpack(n, args)
    if -3 <= n and n <= 4 then
        return _unpack_dispatch[n](args)
    end
    return vararg_unpack(args, 1, n)
end


--- @param obj any
--- @return string
local function _expected_callable_error_msg(obj)
    return "Callable expected, got: " .. tostring(obj)
end


--- @param obj function
--- @return boolean
local function _iscallable(obj)
    if type(obj) == "function" then
        return true
    end
    local mtb = getmetatable(obj)
    return mtb and type(rawget(mtb, '__call')) == "function"
end


--- @param msg string
--- @param level? integer
--- @return string
local function error_handler(msg, level)
    return traceback(msg, level)
end


--- @param thread thread
--- @param msg string
--- @return string
local function thread_error_handler(thread, msg)
    return traceback(thread, msg)
end


local function dqueue_init(n, p, at)
    at[n] = at
    at[p] = at
    return at
end


local function dqueue_push_front(n, p, at, value)
    value[p] = at
    value[n] = at[n]
    at[n][p] = value
    at[n] = value
end


local function dqueue_push_back(n, p, at, value)
    value[n] = at
    value[p] = at[p]
    at[p][n] = value
    at[p] = value
end


local function dqueue_remove(n, p, at)
    local _n = at[n]
    local _p = at[p]
    _p[n] = _n
    _n[p] = _p
    at[n] = at
    at[p] = at
end


local function dqueue_pop_front(n, p, at)
    local value = at[n]
    dqueue_remove(n, p, value)
    if at == value then
        return nil
    end
    return value
end


--- @diagnostic disable-next-line:unused-local,unused-function
local function dqueue_pop_back(n, p, at)
    local value = at[p]
    dqueue_remove(n, p, value)
    if at == value then
        return nil
    end
    return value
end


--- @diagnostic disable-next-line:unused-local
local function dqueue_isempty(n, p, at)
    return at == at[n]
end


local function dqueue_splice(n, p, at, donor)
    if dqueue_isempty(n, p, donor) then
        return
    end

    local tnext = at[p]
    local tprev = at

    local onext = donor[n]
    local oprev = donor[p]

    tnext[n] = onext
    onext[p] = tnext

    oprev[n] = tprev
    tprev[p] = oprev

    donor[n] = donor
    donor[p] = donor
end


local CORO_MAPPING


if debug and debug.getregistry then
    local reg = debug.getregistry()
    if reg then
        local m = reg["__task_coro_mapping__"]
        if m then
            CORO_MAPPING = m
        else
            CORO_MAPPING = setmetatable({}, { __mode = "kv" })
            reg["__task_coro_mapping__"] = CORO_MAPPING
        end
    end
end


if not CORO_MAPPING then
    CORO_MAPPING = setmetatable({}, { __mode = "kv" })
end


--- @return task
local function current_task()
    local t = co_running()
    return t and CORO_MAPPING[t]
end


local function register_task(task)
    CORO_MAPPING[task._thread] = task
end


local is_running

if co_isyieldable then
    is_running = function()
        if not co_isyieldable() then return false end
        local thread, ismain = co_running()
        return not ismain and thread and co_isyieldable and CORO_MAPPING[thread] ~= nil
    end
else
    is_running = function()
        local thread, ismain = co_running()
        return not ismain and thread and CORO_MAPPING[thread] ~= nil
    end
end


--- @return task
local function assert_current_task()
    local t = CORO_MAPPING[co_running()]
    if not t then
        error("No current task")
    end
    return t
end


--- @param obj any
--- @return string
local function ud_tostring(obj)
    local mt = getmetatable(obj)
    local name = mt.__name
    if name then
        if obj._name then
            return string.format("<%s: %s>", name, obj._name)
        else
            return string.format("<%s: %p>", name, obj)
        end
    end
    return tostring(obj)
end


local function report_callback_error(parent, cb, err, ...)
    if select("#", ...) > 1 then
        print(string.format("[ERROR] %s - %s - %s - %s",
            parent, cb, err, vim.inspect({ ... })))
    else
        print(string.format("[ERROR] %s - %s - %s",
            parent, cb, err))
    end
end


--- @param func function
--- @return task._hook
local function hook_init(func)
    return {
        func,
        n = 1,
        c = 1,
        [func] = 1,
    }
end


--- @param hook task._hook
--- @param func function
local function hook_add(hook, func)
    local num = hook[func]
    if num then
        return
    end
    num = hook.n + 1
    hook.n = num
    hook.c = hook.c + 1
    hook[num] = func
    hook[func] = num
end


--- @param hook task._hook
--- @param func function
local function hook_del(hook, func)
    local num = hook[func]
    if not num then
        return
    end
    hook.c = hook.c - 1
    hook[func] = nil
    if num == hook.n then
        hook[num] = nil
        hook.n = hook.n - 1
    else
        hook[num] = false
    end
end


--- @param parent any
--- @param errh task._error_handler?
--- @param func function
--- @param ... any
local function hook_invoke_1(parent, errh, func, ...)
    local ok, err = xpcall(func, errh or error_handler, ...)
    if not ok then
        report_callback_error(parent, func, err, ...)
    end
end


--- @param parent any
--- @param errh task._error_handler?
--- @param hook task._hook|false|nil
local function hook_invoke(parent, errh, hook, ...)
    if not hook then
        return
    end
    if not errh then
        errh = error_handler
    end
    for i = 1, hook.n do
        local func = hook[i]
        if func then
            hook_invoke_1(parent, errh, func, ...)
        end
    end
end


--- @param task task
local function waitlist_detach(task)
    dqueue_remove("_wnext", "_wprev", task)
end


--- @param task task
local function tasklist_detach(task)
    dqueue_remove("_tnext", "_tprev", task)
end


--- @param task task
--- @param tasklist task._task_queue
local function tasklist_tofront(task, tasklist)
    dqueue_push_front("_tnext", "_tprev", tasklist, task)
end


--- @param task task
--- @param tasklist task._task_queue
local function tasklist_toback(task, tasklist)
    dqueue_push_back("_tnext", "_tprev", tasklist, task)
end


--- @param task task
--- @return string
local function _no_scheduler_error_msg(task)
    return "Task " .. tostring(task) .. " has no scheduler"
end


--- @param task task
--- @return string
local function _not_blocked_error_msg(task)
    return "Task " .. tostring(task) .. " not blocked"
end


--- @param task task
local function task_is_blocked(task)
    return task._status == "blocked"
end


--- @param task task
--- @return task.scheduler
local function assert_task_scheduler(task)
    local sched = task._sched
    if not sched then
        error(_no_scheduler_error_msg(task))
    end
    return sched
end


local function _unexpected_scheduler_error_msg(sched, task)
    return string.format("Task (%s) from different scheduler: expecte(%s) ~= got(%s)",
        task, sched, task._sched)
end

local function _task_not_registered_error_msg(sched, task)
    return string.format("Task (%s) not registered with scheduler (%s)",
        task, sched)
end


local function assert_same_scheduler(sched, task)
    if sched ~= task._sched then
        error(_unexpected_scheduler_error_msg(sched, task))
    end
    if not sched._tasks[task] then
        error(_task_not_registered_error_msg(sched, task))
    end
end


--- @param task task
local function task_detach_from_scheduler(task)
    tasklist_detach(task)
    local sched = assert_task_scheduler(task)
    if not task_is_blocked(task) then
        sched._num_ready = sched._num_ready - 1
    end
    sched._num_tasks = sched._num_tasks - 1
    sched._tasks[task] = nil
end


--- @param task task
local function task_close(task)
    CORO_MAPPING[task._thread] = nil
end


--- @param task task
local function task_do_block(task)
    local sched = task._sched
    if not sched then error(_no_scheduler_error_msg(task)) end

    if task ~= sched._running then
        sched._num_ready = sched._num_ready - 1
    end

    tasklist_detach(task)
    tasklist_toback(task, sched._q_blocked)
    task._status = "blocked"
end


local TASK_TERMINAL_STATUS = {
    cancelled = true,
    done = true,
    error = true,
}


--- @param task task
local function task_is_finished(task)
    return TASK_TERMINAL_STATUS[task._status] ~= nil
end

--- @param obj task._wait_queue
--- @return boolean
local function waitlist_isempty(obj)
    return dqueue_isempty("_wnext", "_wprev", obj)
end


--- @param task task
local function task_do_unblock(task, n, args)
    if not task_is_blocked(task) then
        error(_not_blocked_error_msg(task))
    end
    tasklist_detach(task)
    tasklist_toback(task, task._sched._q_ready)
    task._nargs = n
    task._args = args
    task._status = ""
    task._shield = false
end


local function task_prepare_resume(task)
    if not task_is_blocked(task) then
        error(_not_blocked_error_msg(task))
    end
    tasklist_detach(task)
    task._status = ""
end


--- @param obj task._wait_queue
--- @param n integer
--- @param args any|any[]
--- @return integer
local function waitlist_wakeup(obj, n, args)
    local i = 0
    local val = dqueue_pop_front("_wnext", "_wprev", obj)
    while val do
        i = i + 1
        task_do_unblock(val, n, args)
        val = dqueue_pop_front("_wnext", "_wprev", obj)
    end
    return i
end


--- @param obj task._wait_queue
--- @param n integer
--- @param args any|any[]
--- @return boolean
local function waitlist_wakeup_one(obj, n, args)
    local val = dqueue_pop_front("_wnext", "_wprev", obj)
    if val then
        task_do_unblock(val, n, args)
        return true
    end
    return false
end

--- @param task task._task_data
local function task_finish(task, ...)
    local cblist = task._fn
    task._fn = false
    hook_invoke(task, task._errh, cblist, ...)
    if task._q_join then
        waitlist_wakeup(task._q_join, ...)
    end
end

--- @param task task
local function task_handle_cancel(task)
    task_detach_from_scheduler(task)
    task._status = "cancelled"
    task._nargs = 0
    task._args = false
    task_finish(task, nil)
    task_close(task)
end


--- @param task task
local function task_handle_done(task, ...)
    task_detach_from_scheduler(task)
    task._status = "done"
    task._nargs, task._args = _pack(...)
    task_finish(task, true, ...)
    task_close(task)
end


--- @param task task
local function task_handle_error(task, err)
    task_detach_from_scheduler(task)
    task._status = "error"
    task._nargs = 1
    err = thread_error_handler(task._thread, err)
    task._args = err
    task_finish(task, false, err)
    task_close(task)
end


--- @param task task
local function task_do_cancel(task)
    waitlist_detach(task)
    if task._shield then
        task_do_unblock(task, -1, "cancelled")
        return
    end
    task_handle_cancel(task)
end


local function task_do_cancel_force(task)
    task._shield = false
    waitlist_detach(task)
    task_handle_cancel(task)
end

--- @param obj task._wait_queue
--- @return integer
local function waitlist_cancel(obj)
    local i = 0
    local val = dqueue_pop_front("_wnext", "_wprev", obj)
    while val do
        i = i + 1
        task_do_cancel(val)
        val = dqueue_pop_front("_wnext", "_wprev", obj)
    end
    return i
end


local function task_do_yield(task)
    tasklist_toback(task, task._sched._q_yield)
end


--- @param task task
local function on_yield(task)
    task_do_yield(task)
end


--- @param task task
local function on_cancel(task)
    task_do_cancel_force(task)
end


--- @param task task
local function on_block(task)
    task_do_block(task)
end

---
--- @param task task
local function on_block_shielded(task)
    task_do_block(task)
    task._shield = true
end


--- @param task task
local function _move_task_to_front(task)
    tasklist_detach(task)
    tasklist_tofront(task, task._sched._q_ready)
end


--- @param task_to task
--- @param task_from task
local function _copy_scheduler(task_to, task_from)
    --- @type task.scheduler
    local new_sched = task_from._sched
    --- @type task.scheduler
    local old_sched = task_to._sched

    if new_sched ~= old_sched then
        old_sched._num_tasks = old_sched._num_tasks - 1
        old_sched._num_ready = old_sched._num_ready - 1
        old_sched._tasks[task_to] = nil
        new_sched._num_tasks = new_sched._num_tasks + 1
        new_sched._num_ready = new_sched._num_ready + 1
        new_sched._tasks[task_to] = nil
    end

    task_to._sched = new_sched
end


--- @param task task
local function on_reply_transfer_yield(task, other_task)
    task_do_yield(task)
    if other_task and not task_is_blocked(other_task) then
        _copy_scheduler(other_task, task)
        _move_task_to_front(other_task)
    end
end


--- @param task task
local function on_reply_transfer_block(task, other_task)
    task_do_block(task)
    if other_task and not task_is_blocked(other_task) then
        _copy_scheduler(other_task, task)
        _move_task_to_front(other_task)
    end
end


--- @param fn function
--- @param ... any
local function on_scheduler_call(task, fn, ...)
    tasklist_tofront(task, task._sched._q_ready)
    task._nargs, task._args = _pack(xpcall(fn, traceback, ...))
end


--- @type {[task._reply_id]:fun(task,...)}
local TASK_REPLY = setmetatable({
    on_yield,
    on_cancel,
    on_block,
    on_block_shielded,
    on_reply_transfer_yield,
    on_reply_transfer_block,
    on_scheduler_call,
}, {
    __index = function() return on_yield end
})


--- @async
local function task_yield_reply_yield()
    return co_yield(1)
end


--- @async
local function task_yield_reply_cancel()
    return co_yield(2)
end


--- @async
--- @return ...
local function task_yield_reply_block(...)
    return co_yield(3, ...)
end

--- @async
--- @return ...
local function task_yield_reply_block_shielded(...)
    return co_yield(4, ...)
end

--- @params fn function
--- @params ... any
--- @return any
local function task_yield_reply_scheduler_call(fn, ...)
    return co_yield(6, fn, ...)
end



local function _task_result_cancelled()
    return nil, "cancelled"
end


local function _task_result_cancelled_propagate()
    return task_yield_reply_cancel()
end


local function _task_result_error(task)
    return false, task._args
end


local function _task_result_done(task)
    return true, _unpack(task._nargs, task._args)
end


local _task_result_mapping = {
    cancelled = _task_result_cancelled,
    error = _task_result_error,
    done = _task_result_done,
}

local _task_result_mapping_propagated = {
    cancelled = _task_result_cancelled_propagate,
    error = _task_result_error,
    done = _task_result_done,
}


--- @param task task
--- @return boolean?
--- @return ... any
local function task_result(task)
    local handler = _task_result_mapping[task._status]
    if not handler then
        error("Task not finished")
    end
    return handler(task)
end

--- @param task task
--- @return boolean?
--- @return ... any
local function task_result_propagate_cancel(task)
    local handler = _task_result_mapping_propagated[task._status]
    if not handler then
        error("Task not finished")
    end
    return handler(task)
end


--- @param task task
--- @param func task._result_handler
local function task_result_apply(task, func)
    hook_invoke_1(task, task._errh, func, task_result(task))
end


--- @param task task
local function task_args_release(task)
    local n = task._nargs
    local args = task._args
    task._nargs = 0
    task._args = false
    return _unpack(n, args)
end


local function invalid_step_reply(step_id)
    error(string.format(
        "Invalid task reply: expected number, got \"%s\": %s",
        type(step_id),
        tostring(step_id)
    ), 2)
end


--- @param task task
--- @param func task._result_handler
local function task_late_callback(task, func)
    if is_running() then
        return task_yield_reply_scheduler_call(task_result_apply, task, func)
    end
    return task_result_apply(task, func)
end

--- @async
--- @param obj task._wait_queue
local function waitlist_block_on(obj)
    dqueue_push_back("_wnext", "_wprev", obj, assert_current_task())
    return task_yield_reply_block()
end

--- @async
--- @param obj task._wait_queue
local function waitlist_block_shielded_on(obj)
    dqueue_push_back("_wnext", "_wprev", obj, assert_current_task())
    return task_yield_reply_block_shielded()
end


local function wait_cancelled()
    if is_running() then
        return task_yield_reply_cancel()
    end
    error("Wait of a cancelled object outside of a task execution", 2)
end


--- @param task task
local function assert_current(task)
    local co = co_running()
    if not co then
        error("Not a coroutine")
    end
    if co ~= task._thread then
        error(string.format("Not a current task %s ~= %s", co, task._thread))
    end
end


--- @param task task
local function assert_not_current(task)
    local co = co_running()
    if not co then
        return
    end
    if co == task._thread then
        error("Attempt to unblock current task: " .. tostring(task))
    end
end


--- @param task task
--- @param step_id task._reply_id
local function task_handle_continue(task, step_id, ...)
    if not step_id then
        step_id = 1
    elseif type(step_id) ~= "number" then
        invalid_step_reply(step_id)
    end
    return TASK_REPLY[step_id](task, ...)
end


--- @param task task
--- @param status boolean
--- @param ... any
local function task_handle_step_reply(task, status, ...)
    if not status then
        task_handle_error(task, ...)
        return
    end
    if co_status(task._thread) == "dead" then
        task_handle_done(task, ...)
        return
    end
    task_handle_continue(task, ...)
end


--- @param task task
local function task_step(task)
    task_handle_step_reply(task, co_resume(task._thread, task_args_release(task)))
end

--- @param task task
local function task_resume(task, ...)
    task_handle_step_reply(task, co_resume(task._thread, ...))
end


--- @param func function
function __task:fn(func)
    if not _iscallable(func) then
        error(_expected_callable_error_msg(func))
    end

    if task_is_finished(self) then
        return task_late_callback(self, func)
    end

    local cblist = self._fn

    if cblist then
        hook_add(cblist, func)
    else
        self._fn = hook_init(func)
    end
end

--- @param func function
function __task:delfn(func)
    local cblist = self._fn
    if cblist then
        hook_del(cblist, func)
    end
end

function __task:iscurrent()
    return co_running() == self._thread
end

--- @async
function __task:block()
    if co_running() ~= self._thread then
        return task_do_block(self)
    end
    return task_yield_reply_block()
end

function __task:unblock(...)
    assert_not_current(self)
    return task_do_unblock(self, _pack(...))
end

--- @param task task
local function task_wait(task, shielded)
    if co_running() == task._thread then
        error("Attempt to wait current task")
    end
    if task_is_finished(task) then
        if shielded then
            return task_result(task)
        end
        return task_result_propagate_cancel(task)
    end
    if not task._q_join then
        local q = { _wnext = false, _wprev = false }
        q._wnext = q
        q._wprev = q
        task._q_join = q
    end
    if shielded then
        return waitlist_block_shielded_on(task._q_join)
    end
    return waitlist_block_on(task._q_join)
end


--- @async
function __task:wait()
    return task_wait(self, false)
end

--- @async
function __task:pwait()
    return task_wait(self, true)
end

--- @return boolean
function __task:isblocked()
    return self._status == "blocked"
end

--- @return boolean
function __task:iscancelled()
    return self._status == "cancelled"
end

--- @return boolean
function __task:isdone()
    return self._status == "done"
end

function __task:isready()
    return self._status == "" and co_status(self._thread) ~= "dead"
end

function __task:close()
    if co_running() ~= self._thread then
        return task_do_cancel_force(self)
    end
    return task_yield_reply_cancel()
end

--- @async
function __task:yield()
    assert_current(self)
    return task_yield_reply_yield()
end

--- @return task.scheduler
function __task:scheduler()
    return assert_task_scheduler(self)
end

--- @return string
function __task:status()
    local status = self._status
    if status ~= "" then
        return status
    end
    return co_status(self._thread)
end

local task_mt = {
    __name = "task.instance",
    __tostring = ud_tostring,
    __index = __task,
}


--- @param nargs integer
--- @param args any
--- @return task
local function new_task(func, nargs, args)
    --- @type task._task_data
    local t = {
        _thread = co_create(func),
        _nargs = nargs,
        _args = args,
        _fn = false,
        _status = "",
        _tnext = false,
        _tprev = false,
        _wnext = false,
        _wprev = false,
        _shield = false,
        _sched = false,
        _q_join = false,
        _errh = false,
    }

    t._tnext = t
    t._tprev = t
    t._wnext = t
    t._wprev = t

    --- @cast t task
    return setmetatable(t, task_mt)
end


local scheduler_events = {
    step = true,
    spawn = true,
}


--- @param sched task.scheduler
--- @param name string
--- @param ... any
local function run_sched_hook(sched, name, ...)
    hook_invoke(sched, error_handler, sched._fn[name], sched, ...)
end


--- @param sched task.scheduler
local function scheduler_step_ready_task(sched)
    local t = dqueue_pop_front("_tnext", "_tprev", sched._q_ready)
    if not t then
        return false
    end

    if not t:isready() then
        error(string.format("Task (%s) not ready", t))
    end

    assert_same_scheduler(sched, t)
    sched._running = t
    task_step(t)
    sched._running = false
    return true
end


local function scheduler_resume_blocked_task(sched, task, ...)
    assert_same_scheduler(sched, task)
    sched._running = task
    task_resume(task, ...)
    sched._running = false
end


--- @param eventname string
--- @param func function
function __scheduler:fn(eventname, func)
    if not _iscallable(func) then
        error(_expected_callable_error_msg(func))
    end
    if not scheduler_events[eventname] then
        return
    end
    local cblist = self._fn[eventname]
    if cblist then
        hook_add(cblist, func)
    else
        self._fn[eventname] = hook_init(func)
    end
end

--- @param eventname string
--- @param func function
function __scheduler:delfn(eventname, func)
    local cblist = self._fn[eventname]
    if cblist then
        hook_del(cblist, func)
    end
end

--- @param num_steps? integer
function __scheduler:step(num_steps)
    dqueue_splice("_tnext", "_tprev", self._q_ready, self._q_yield)
    if num_steps and num_steps > 0 then
        while num_steps > 0 and scheduler_step_ready_task(self) do
            num_steps = num_steps - 1
        end
    else
        repeat
            local hasmore = scheduler_step_ready_task(self)
        until not hasmore
    end
    dqueue_splice("_tnext", "_tprev", self._q_ready, self._q_yield)
    run_sched_hook(self, "step")
    return self._num_tasks
end

--- @param task task
--- @param ... any
function __scheduler:resume(task, ...)
    if co_running() == task._thread then
        error("Resume current task")
    end

    task_prepare_resume(task)
    scheduler_resume_blocked_task(self, task, ...)

    repeat until not scheduler_step_ready_task(self)
    dqueue_splice("_tnext", "_tprev", self._q_ready, self._q_yield)
    run_sched_hook(self, "step")
    return self._num_tasks
end

--- @param func async fun(...):...
--- @return task
function __scheduler:spawn(func, ...)
    local t = new_task(func, _pack(...))
    t._sched = self
    dqueue_push_back("_tnext", "_tprev", self._q_ready, t)
    self._num_tasks = self._num_tasks + 1
    self._num_ready = self._num_ready + 1
    self._tasks[t] = true
    register_task(t)
    run_sched_hook(self, "spawn", t)
    return t
end

local scheduler_resume = __scheduler.resume
local scheduler_spawn = __scheduler.spawn


--- @param ... any
function __task:resume(...)
    local sched = assert_task_scheduler(self)
    return scheduler_resume(sched, self, ...)
end

function __task:spawn(func, ...)
    local sched = assert_task_scheduler(self)
    return scheduler_spawn(sched, func, ...)
end

function __scheduler:current()
    local t = self._running
    if not t then
        return nil
    end
    return t
end

--- @param sched task.scheduler
local function _maybe_cancel_current(sched)
    local t = sched._running
    if t then
        if t._thread == co_running() then
            return true
        else
            task_do_cancel(t)
            return false
        end
    end
end


--- @param sched task.scheduler
--- @param q task._task_queue
--- @param limit 1|0
local function _maybe_cancel_queue(sched, q, limit)
    local task = dqueue_pop_front("_tnext", "_tprev", q)
    while task do
        sched._num_ready = sched._num_ready - limit
        task_do_cancel(task)
        task = dqueue_pop_front("_tnext", "_tprev", q)
    end
end


function __scheduler:close()
    local was_running = _maybe_cancel_current(self)
    local limit = was_running and 1 or 0
    while self._num_tasks > limit do
        while self._num_ready > 0 do
            _maybe_cancel_queue(self, self._q_ready, 1)
        end
        _maybe_cancel_queue(self, self._q_blocked, 0)
    end
end

--- @return integer
function __scheduler:nblocked()
    return self._num_tasks - self._num_ready
end

--- @return integer
function __scheduler:nready()
    return self._num_ready
end

--- @return integer
function __scheduler:ntasks()
    return self._num_tasks
end

local function collect_tasks(q, t, n)
    local task = q._tnext
    while task ~= q do
        n = n + 1
        t[n] = task
        task = task._tnext
    end
    return n
end

function __scheduler:tasks()
    local t = {}
    local n = collect_tasks(self._q_ready, t, 0)
    n = collect_tasks(self._q_yield, t, n)
    collect_tasks(self._q_blocked, t, n)
    return t
end

local scheduler_mt = {
    __name = "task.scheduler",
    __tostring = ud_tostring,
    __index = __scheduler,
}


--- @return task.scheduler
local function new_scheduler()
    --- @type task._scheduler_data
    local s = {
        _q_ready = dqueue_init("_tnext", "_tprev", {}),
        _q_blocked = dqueue_init("_tnext", "_tprev", {}),
        _q_yield = dqueue_init("_tnext", "_tprev", {}),
        _running = false,
        _num_tasks = 0,
        _num_ready = 0,
        _fn = {},
        _tasks = {},
    }

    --- @cast s task.scheduler
    return setmetatable(s, scheduler_mt)
end


--- @return task.scheduler?
local function current_scheduler()
    local t = current_task()
    if not t then
        return nil
    end
    return t._sched or nil
end


--- @param func function
--- @param ... any
local function spawn(func, ...)
    local sched = current_scheduler()
    if not sched then
        error("No current scheduler")
    end
    return scheduler_spawn(sched, func, ...)
end


--- @param ... any
--- @return integer
function __signal:post(...)
    if waitlist_isempty(self) then
        return 0
    end
    return waitlist_wakeup(self, _pack(...))
end

--- @param ... any
--- @return boolean
function __signal:postone(...)
    if waitlist_isempty(self) then
        return false
    end
    return waitlist_wakeup_one(self, _pack(...))
end

--- @return boolean
function __signal:isempty()
    return waitlist_isempty(self)
end

--- @async
--- @return ... any
function __signal:wait()
    return waitlist_block_on(self)
end

--- @async
--- @return ... any
function __signal:pwait()
    return waitlist_block_shielded_on(self)
end

function __signal:close()
    return waitlist_cancel(self)
end

local signal_mt = {
    __name = "task.signal",
    __tostring = ud_tostring,
    __index = __signal,
    __call = __signal.post,
}


--- @return task.signal
local function new_signal()
    --- @type task._wait_queue
    local s = {
        _wnext = false,
        _wprev = false,
    }
    s._wnext = s
    s._wprev = s

    --- @cast s task.signal
    return setmetatable(s, signal_mt)
end


--- @param ... any
function __event:post(...)
    if self._state ~= 0 then
        error("Attempt to post fired event")
    end

    local n, args = _pack(...)
    self._state = n + 4
    self._args = args

    waitlist_wakeup(self, n, args)

    hook_invoke(self, nil, self._fn, ...)
    self._fn = false
end

--- @async
--- @return ... any
function __event:wait()
    if self._state == -1 then
        return wait_cancelled()
    end
    local state = self._state
    if state > 0 then
        return _unpack(state - 4, self._args)
    end
    return waitlist_block_on(self)
end

--- @async
--- @return ... any
function __event:pwait()
    if self._state == -1 then
        return _task_result_cancelled()
    end
    local state = self._state
    if state > 0 then
        return _unpack(state - 4, self._args)
    end
    return waitlist_block_shielded_on(self)
end

--- @return boolean
--- @return ... any
function __event:trywait()
    local state = self._state
    if state == 0 then
        return false
    end
    if state < 0 then
        return wait_cancelled()
    end
    return true, _unpack(state - 4, self._args)
end

--- @return boolean|nil
--- @return ... any
function __event:trypwait()
    local state = self._state
    if state == 0 then
        return false
    end
    if state < 0 then
        return _task_result_cancelled()
    end
    return true, _unpack(state - 4, self._args)
end

function __event:close()
    self._state = -1
    waitlist_cancel(self)
end

--- @return boolean
function __event:isposted()
    return self._state > 0
end

--- @return boolean
function __event:iscancelled()
    return self._state == -1
end

--- @param func function
function __event:fn(func)
    if not _iscallable(func) then
        error(_expected_callable_error_msg(func))
    end
    local cbt = self._fn
    if cbt then
        hook_add(cbt, func)
        return
    end
    self._fn = hook_init(func)
end

--- @param func function
function __event:delfn(func)
    local cbt = self._fn
    if cbt then
        hook_del(cbt, func)
    end
end

function __event:reset()
    self._state = -1
    waitlist_cancel(self)
    self._state = 0
    self._args = false
    self._fn = false
end

--- @return task.event.state
function __event:state()
    local state = self._state
    if state == 0 then return "init" end
    if state > 0 then return "posted" end
    return "cancelled"
end

local event_mt = {
    __name = "task.event",
    __tostring = ud_tostring,
    __index = __event,
    __call = __event.post,
}


--- @return task.event
local function new_event()
    --- @type task._event_data
    local ev = {
        _wnext = false,
        _wprev = false,
        _args = false,
        _fn = false,
        _state = 0,
    }
    ev._wnext = ev
    ev._wprev = ev
    --- @cast ev task.event
    return setmetatable(ev, event_mt)
end


--- @param a integer
--- @param b integer
--- @return integer
local function _max(a, b)
    if b < a then
        return a
    end
    return b
end


--- @param n number?
--- @return integer
local function tointeger(n)
    return (n - n % 1)
end


--- @param value any
--- @param default integer
--- @return integer
local function _posint(value, default)
    if not value then
        return default
    end
    local n = tonumber(value)
    return n >= default and tointeger(n) or default
end



function __sem:post(value, maxvalue)
    local state = self._state
    if state < 0 then
        return -1
    end

    local v = _posint(value, 0)
    if v <= 0 then
        return state
    end

    local mv = _posint(maxvalue, 0)
    if mv > 0 then
        state = _max(state + v, mv)
    else
        state = state + v
    end

    while state > 0 do
        local t = dqueue_pop_front("_wnext", "_wprev", self)
        if not t then
            break
        end
        state = state - 1
        task_do_unblock(t, 1)
    end

    self._state = state

    return state
end

--- @async
function __sem:wait()
    local state = self._state
    if state < 0 then
        return wait_cancelled()
    end
    if state == 0 then
        return waitlist_block_on(self)
    end
    state = state - 1
    self._state = state
    return state
end

--- @async
function __sem:pwait()
    local state = self._state
    if state < 0 then
        return _task_result_cancelled()
    end
    if state == 0 then
        return waitlist_block_shielded_on(self)
    end
    state = state - 1
    self._state = state
    return state
end

function __sem:trywait()
    local state = self._state
    if state < 0 then
        return wait_cancelled()
    end
    if state == 0 then
        return false
    end
    state = state - 1
    self._state = state
    return true, state
end

--- @param self task.sem
function __sem:close()
    self._state = -1
    waitlist_cancel(self)
end

--- @param self task.sem
function __sem:reset(value)
    self._state = -1
    waitlist_cancel(self)
    self._state = _posint(value, 0)
end

--- @return boolean
function __sem:isopen()
    return self._state > 0
end

--- @return boolean
function __sem:iscancelled()
    return self._state < 0
end

--- @param self task.sem
function __sem:state()
    return self._state
end

local sem_mt = {
    __name = "task.semaphore",
    __tostring = ud_tostring,
    __index = __sem,
}


--- @return task.sem
local function new_sem(state)
    --- @type task._sem_data
    local s = {
        _wnext = false,
        _wprev = false,
        _state = _posint(state, 0),
    }
    s._wnext = s
    s._wprev = s
    --- @cast s task.sem
    return setmetatable(s, sem_mt)
end

function __latch:post(value)
    local state = self._state
    if state <= 0 then
        return state
    end

    state = _max(state - _posint(value, 1), 0)
    if state == 0 then
        waitlist_wakeup(self, 0)
    end

    return state
end

--- @async
function __latch:wait()
    local state = self._state
    if state < 0 then
        return wait_cancelled()
    end
    if state > 0 then
        return waitlist_block_on(self)
    end
end

--- @async
function __latch:pwait()
    local state = self._state
    if state < 0 then
        return _task_result_cancelled()
    end
    if state > 0 then
        return waitlist_block_shielded_on(self)
    end
end

function __latch:trywait()
    local state = self._state
    if state < 0 then
        return wait_cancelled()
    end
    return state == 0
end

function __latch:trypwait()
    local state = self._state
    if state < 0 then
        return _task_result_cancelled()
    end
    return state == 0
end

--- @param self task.sem
function __latch:close()
    self._state = -1
    waitlist_cancel(self)
end

--- @param self task.sem
function __latch:reset(value)
    self._state = -1
    waitlist_cancel(self)
    self._state = _posint(value, 0)
end

--- @return boolean
function __latch:isopen()
    return self._state == 0
end

--- @return boolean
function __latch:iscancelled()
    return self._state < 0
end

--- @param self task.sem
function __latch:state()
    return self._state
end

local latch_mt = {
    __name = "task.latch",
    __tostring = ud_tostring,
    __index = __latch,
}

--- @return task.latch
local function new_latch(state)
    --- @type task._latch_data
    local l = {
        _wnext = false,
        _wprev = false,
        _state = _posint(state, 0),
    }
    l._wnext = l
    l._wprev = l
    --- @cast l task.latch
    return setmetatable(l, latch_mt)
end


--- @async
function __chan:post(...)
    if not self._tx then
        return _task_result_cancelled()
    end
    local n, args = _pack(...)
    repeat
        if waitlist_wakeup_one(self._rx, n, args) then
            return true
        end
        waitlist_block_on(self._tx)
    until self._tx
    return _task_result_cancelled()
end

function __chan:trypost(...)
    if not self._tx then
        return _task_result_cancelled()
    end
    return waitlist_wakeup_one(self._rx, _pack(...))
end

--- @async
function __chan:wait()
    if not self._rx then
        return wait_cancelled()
    end
    waitlist_wakeup_one(self._tx, 0)
    return waitlist_block_on(self._rx)
end

--- @async
function __chan:pwait()
    if not self._rx then
        return _task_result_cancelled()
    end
    waitlist_wakeup_one(self._tx, 0)
    return waitlist_block_shielded_on(self._rx)
end

function __chan:trywait()
    if not self._rx then
        return wait_cancelled()
    end
    if waitlist_wakeup_one(self._tx, 0) then
        return true, waitlist_block_on(self._rx)
    end
    return false
end

function __chan:trypwait()
    if not self._rx then
        return _task_result_cancelled()
    end
    if waitlist_wakeup_one(self._tx, 0) then
        return true, waitlist_block_on(self._rx)
    end
    return false
end

--- @return boolean
function __chan:iscancelled()
    return not (self._tx and self._rx)
end

function __chan:close()
    local tx = self._tx
    local rx = self._rx
    self._tx = nil
    self._rx = nil
    waitlist_cancel(tx)
    waitlist_cancel(rx)
end

local chan_mt = {
    __name = "task.chan",
    __tostring = ud_tostring,
    __index = __chan,
}


local function new_chan()
    --- @type task._chan_data
    local s = {
        _tx = { _wnext = false, _wprev = false },
        _rx = { _wnext = false, _wprev = false },
    }
    --- @cast s task.chan
    return setmetatable(s, chan_mt)
end


--- @param capacity integer
--- @return _ring_queue
local function rq_init(capacity)
    return {
        r = 0,
        w = 0,
        c = _posint(capacity, 1),
        n = 0,
    }
end


--- @param q _ring_queue
--- @param value any
--- @return boolean
local function rq_push(q, value)
    local n, c = q.n, q.c
    if n == c then
        return false
    end

    local idx = (q.w + 1) % c
    q.w = idx
    q.n = n + 1
    q[idx + 1] = value

    return true
end

--- @param q _ring_queue
--- @param value any
--- @return boolean
local function rq_push_wrap(q, value)
    local n, c = q.n, q.c
    local idx = (q.w + 1) % c
    q.w = idx
    q[idx + 1] = value

    if n == c then
        q.r = idx
    else
        q.n = n + 1
    end

    return true
end


--- @param q _ring_queue
--- @return boolean
--- @return any
local function rq_pop(q)
    if q.n == 0 then
        return false
    end

    q.n = q.n - 1
    local idx = (q.r + 1) % q.c
    q.r = idx

    return true, q[idx + 1]
end


function __bqueue:post(value)
    while self._q do
        if rq_push(self._q, value) then
            waitlist_wakeup_one(self._rx, 0)
            return true
        end
        waitlist_block_on(self._tx)
    end

    if not self._q then
        return _task_result_cancelled()
    end
end

function __bqueue:postforce(value)
    if not self._q then
        return _task_result_cancelled()
    end
    rq_push_wrap(self._q, value)
    return waitlist_wakeup_one(self._rx, 0)
end

function __bqueue:trypost(value)
    local q = self._q
    if not q then
        return _task_result_cancelled()
    end
    if rq_push(q, value) then
        waitlist_wakeup_one(self._rx, 0)
        return true
    end
    return false
end

--- @async
--- @param self task.bqueue
function __bqueue:wait()
    while self._q do
        local hasval, value = rq_pop(self._q)
        if hasval then
            waitlist_wakeup_one(self._tx, 0)
            return value
        end
        waitlist_block_on(self._rx)
    end
    wait_cancelled()
end

--- @async
--- @param self task.bqueue
function __bqueue:pwait()
    while self._q do
        local hasval, value = rq_pop(self._q)
        if hasval then
            waitlist_wakeup_one(self._tx, 0)
            return value
        end
        waitlist_block_shielded_on(self._rx)
    end
    return _task_result_cancelled()
end

function __bqueue:trywait()
    local q = self._q
    if not q then
        return wait_cancelled()
    end
    return rq_pop(q)
end

function __bqueue:trypwait()
    local q = self._q
    if not q then
        return _task_result_cancelled()
    end
    return rq_pop(q)
end

--- @return boolean
function __bqueue:iscancelled()
    return not self._q
end

function __bqueue:close()
    self._q = nil
    waitlist_cancel(self._tx)
    waitlist_cancel(self._rx)
end

local bqueue_mt = {
    __name = "task.bounded_queue",
    __tostring = ud_tostring,
    __index = __bqueue,
}


--- @return task.bqueue
local function new_bqueue(capacity)
    --- @type task._bqueue_data
    local bq = {
        _q = rq_init(capacity),
        _tx = { _wnext = false, _wprev = false },
        _rx = { _wnext = false, _wprev = false },
    }

    bq._tx._wnext = bq._tx
    bq._tx._wprev = bq._tx
    bq._rx._wnext = bq._rx
    bq._rx._wprev = bq._rx

    --- @cast bq task.bqueue
    return setmetatable(bq, bqueue_mt)
end

--- @param value any
function __bwqueue:post(value)
    if not self._q then
        error("Attempt to push after cancel")
    end
    rq_push_wrap(self._q, value)
    waitlist_wakeup_one(self, 0)
end

--- @param value any
function __bwqueue:trypost(value)
    if not self._q then
        return false
    end
    rq_push_wrap(self._q, value)
    waitlist_wakeup_one(self, 0)
    return true
end

--- @async
--- @return any
function __bwqueue:wait()
    while self._q do
        local hasval, value = rq_pop(self._q)
        if hasval then
            return value
        end
        waitlist_block_on(self)
    end
    wait_cancelled()
end

--- @return boolean
--- @return any
function __bwqueue:trywait()
    local q = self._q
    if not q then
        return false, "cancelled"
    end
    return rq_pop(q)
end

function __bwqueue:iscancelled()
    self._q = nil
end

function __bwqueue:close()
    self._q = nil
    waitlist_cancel(self)
end

local wqueue_mt = {
    __name = "task.bounded_wrapping_queue",
    __tostring = ud_tostring,
    __index = __bwqueue,
    __call = __bwqueue.post,
}

--- @return task.wqueue
local function new_bwqueue(capacity)
    --- @type task._bwqueue_data
    local wq = {
        _q = rq_init(capacity),
        _wnext = false,
        _wprev = false
    }

    wq._wnext = wq
    wq._wprev = wq

    --- @cast wq task.wqueue
    return setmetatable(wq, wqueue_mt)
end


--- @return _array_linked_queue
local function alq_new()
    return {
        h = 0,
        t = 0,
        f = 0,
        n = 0,
    }
end


--- @param q _array_linked_queue
local function alq_init0(q)
    q.h = 0
    q.t = 0
    q.n = 0
    q.f = 0
end


--- @param q _array_linked_queue
--- @param value any
local function alq_init1(q, value)
    q.h = 1
    q.t = 1
    q.n = 1
    q.f = 0
    q[1] = 0
    q[2] = value
end


--- @param q _array_linked_queue
--- @param value any
local function alq_push(q, value)
    if q.n == 0 then
        alq_init1(q, value)
        return
    end

    local at = 0
    if q.f > 0 then
        at = q.f
        q.f = q[at]
    else
        at = q.n * 2 + 1
    end

    q[at] = 0
    q[at + 1] = value
    q[q.t] = at
    q.t = at
    q.n = q.n + 1
end


--- @param q _array_linked_queue
--- @return boolean
--- @return any
local function alq_pop(q)
    if q.n == 0 then
        return false, nil
    end

    q.n = q.n - 1

    if q.n == 0 then
        local v = q[q.h + 1]
        q[q.h + 1] = false
        alq_init0(q)
        return true, v
    end

    local idx_head = q.h
    local idx_next = q[idx_head]
    q[idx_head] = q.f
    q.h = idx_next

    local v = q[idx_head + 1]
    q[idx_head + 1] = false

    return true, v
end


--- @param value any
function __uqueue:post(value)
    if not self._q then
        return _task_result_cancelled()
    end
    alq_push(self._q, value)
    waitlist_wakeup_one(self, 0)
    return true
end

--- @diagnostic disable-next-line:inject-field
__uqueue.trypost = __uqueue.post


--- @async
--- @return any
function __uqueue:wait()
    while self._q do
        local hasval, value = alq_pop(self._q)
        if hasval then
            return value
        end
        waitlist_block_on(self)
    end
    wait_cancelled()
end

--- @async
--- @return boolean|nil
--- @return any
function __uqueue:pwait()
    while self._q do
        local hasval, value = alq_pop(self._q)
        if hasval then
            return true, value
        end
        waitlist_block_shielded_on(self)
    end
    return _task_result_cancelled()
end

--- @return boolean
--- @return any
function __uqueue:trywait()
    local q = self._q
    if not q then
        return wait_cancelled()
    end
    return alq_pop(q)
end

--- @return boolean|nil
--- @return any
function __uqueue:trypwait()
    local q = self._q
    if not q then
        return _task_result_cancelled()
    end
    return alq_pop(q)
end

function __uqueue:iscancelled()
    self._q = nil
end

function __uqueue:close()
    self._q = nil
    waitlist_cancel(self)
end

local uqueue_mt = {
    __name = "task.undbounded_queue",
    __tostring = ud_tostring,
    __index = __uqueue,
    __call = __uqueue.post,
}


--- @return task.uqueue
local function new_uqueue()
    --- @type task._uqueue_data
    local uq = {
        _q = alq_new(),
        _wnext = false,
        _wprev = false,
    }

    uq._wnext = uq
    uq._wprev = uq

    --- @cast uq task.uqueue
    return setmetatable(uq, uqueue_mt)
end


--- @class task.module
return {
    new_scheduler = new_scheduler,
    scheduler = current_scheduler,
    spawn = spawn,
    signal = new_signal,
    event = new_event,
    sem = new_sem,
    latch = new_latch,
    chan = new_chan,
    bqueue = new_bqueue,
    bwqueue = new_bwqueue,
    uqueue = new_uqueue,
    current = current_task,
    isrunning = is_running,
    yield = task_yield_reply_yield,
    block = task_yield_reply_block,
    cancel = task_yield_reply_cancel,
}

--- task.lua ends here
