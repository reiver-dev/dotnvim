--- Task scheduler

local co_yield = coroutine.yield
local co_create = coroutine.create
local co_resume = coroutine.resume
local co_status = coroutine.status
local co_running = coroutine.running
local vararg_unpack = table.unpack or unpack


local function vararg_unpack_n(tbl)
    if tbl then
        return vararg_unpack(tbl, 1, tbl.n or #tbl)
    end
end


local function error_handler()
    return debug.traceback
end


local function dqueue_init(n, p, at)
    at[n] = at
    at[p] = at
    return at
end


local function dqueue_push_front(n, p, at, value)
    value[n] = at
    value[p] = at[p]
    at[p][n] = value
    at[p] = value
end


local function dqueue_push_back(n, p, at, value)
    value[p] = at
    value[n] = at[n]
    at[n][p] = value
    at[n] = value
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
    return value
end


local function dqueue_pop_back(n, p, at)
    local value = at[p]
    dqueue_remove(n, p, value)
    return value
end


local function dqueue_isempty(n, p, at)
    return at == at[n]
end


local function _dqueue_it(state, val)
    val = val[state.n]
    if val == state.at then
        return nil
    end
    return val
end


local function _dqueue_pop(state, val)
    val = dqueue_pop_front(state.n, state.p, state.at)
    if val == state.at then
        return nil
    end
    return val
end


local function dqueue_iter(n, p, at, func)
    return _dqueue_it, { n = n, p = p, at = at }, at
end


local function dqueue_drain(n, p, at, func)
    return _dqueue_pop, { n = n, p = p, at = at }, at
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


local function current_task()
    return CORO_MAPPING[co_running()]
end


local function assert_current_task()
    local t = CORO_MAPPING[co_running()]
    if not t then
        error("No current task")
    end
    return t
end


local function ud_tostring(self)
    local mt = getmetatable(self)
    local name = mt.__name
    if name then
        if self._name then
            return string.format("<%s: %s>", name, self._name)
        else
            return string.gsub(tostring(self), "userdata", "task.scheduler")
        end
    end
    return tostring(self)
end


local function pack(...)
    return { n = select("#", ...), ... }
end


local function report_callback_error(task, cb, err, ...)
    if select("#", ...) > 1 then
        print(string.format("[ERROR] %s - %s - %s - %s",
            task, cb, err, vim.inspect({ ... })))
    else
        print(string.format("[ERROR] %s - %s - %s",
            task, cb, err))
    end
end


local function task_finished(task, ...)
    local cblist = task._callbacks
    task._callbacks = false

    if not cblist then
        return
    end

    local errh = task._error_handler or error_handler()

    for cb in pairs(cblist) do
        local ok, err = xpcall(cb, errh, ...)
        if not ok then
            report_callback_error(task, cb, err, ...)
        end
    end
end


local function task_dispose(task)
    local sched = task._sched
    task._sched = nil
    sched._num_task = sched._num_task - 1
    sched._tasks[task] = nil
end


local function task_close(task)
    CORO_MAPPING[task._thread] = nil
end


local function task_status(task)
    local status = task._status
    if status and status ~= "" then
        return status
    end
    return co_status(task._thread)
end


local function task_do_block(task)
    local sched = task._sched
    if task ~= sched._running then
        sched._num_ready = sched._num_ready - 1
    end
    dqueue_remove("_tnext", "_tprev", task)
    dqueue_push_front("_tnext", "_tprev", sched._q_blocked, task)
    task._status = "blocked"
end



local TASK_TERMINAL_STATUS = {
    cancelled = true,
    done = true,
    error = true,
}


local function task_is_blocked(task)
    return task._status == "blocked"
end


local function task_is_finished(task)
    return TASK_TERMINAL_STATUS[task._status] ~= nil
end


local function task_do_unblock(task, args)
    dqueue_remove("_tnext", "_tprev", task)
    dqueue_push_front("_tnext", "_tprev", task._sched._q_ready, task)
    task._args = args
    task._status = ""
end

local function task_handle_cancel(task)
    task._status = "cancelled"
    task_dispose(task)
    task_finished(task, nil)
    task_close(task)
end


local function task_do_cancel(task)
    dqueue_remove("_tnext", "_tprev", task)
    dqueue_remove("_wnext", "_wprev", task)
    task_handle_cancel(task)
end


local function on_yield(task)
    local sched = task._sched
    dqueue_push_back("_tnext", "_tprev", sched._q_yield, task)
    sched._num_tasks = sched._num_tasks + 1
end


local function on_cancel(task)
    task_do_cancel(task)
end


local function on_block(task)
    task_do_block(task)
end


local function on_reply_transfer_yield(task, other_task)
    local sched = task._sched
    dqueue_push_back("_tnext", "_tprev", sched._q_yield, task)
    if other_task and not task_is_blocked(other_task) then
        other_task._sched = sched
        dqueue_remove("_tnext", "_tprev", other_task)
        dqueue_push_front("_tnext", "_tprev", sched)
    end
end


local function on_reply_transfer_block(task, other_task)
    task_do_block(task)
    if other_task and not task_is_blocked(other_task) then
        local sched = task._sched
        other_task._sched = sched
        dqueue_remove("_tnext", "_tprev", other_task)
        dqueue_push_front("_tnext", "_tprev", sched)
    end
end



local TASK_REPLY = setmetatable({
    on_yield,
    on_cancel,
    on_block,
    on_reply_transfer_yield,
    on_reply_transfer_block,
}, {
    __index = function() return on_yield end
})


local function task_handle_done(task, ...)
    task._status = "done"
    task_dispose(task)
    task._args = pack(...)
    task_finished(task, true, ...)
    task_close(task)
end


local function task_handle_error(task, err)
    task._status = "error"
    task_dispose(task)
    task._args = err
    task_finished(task, false, err)
    task_close(task)
end


local function task_handle_late_result(task)
    local status = task._status
    if status == "cancelled" then
        return task_finished(task, nil)
    end
    if status == "error" then
        return task_finished(task, false, task._args)
    end
    if status == "done" then
        return task_finished(task, true, vararg_unpack_n(task._args))
    end
end


local function invalid_step_reply(step_id)
    error(string.format(
        "Invalid task reply: expected number, got \"%s\": %s",
        type(step_id),
        tostring(step_id)
    ), 2)
end


local function task_handle_continue(task, step_id, ...)
    if not step_id then
        step_id = 1
    elseif type(step_id) ~= "number" then
        invalid_step_reply(step_id)
    end
    return TASK_REPLY[step_id](task, ...)
end


local function handle_reply(task, status, ...)
    if not status then
        task_handle_error(task, ...)
    end
    if co_status(task._thread) == "dead" then
        task_handle_done(task, ...)
    end
    task_handle_continue(task, ...)
end


local function task_args_release(task)
    local args = task._args
    if args then
        task._args = false
        return vararg_unpack_n(args)
    end
end


local function task_resume(task)
    return co_resume(task._thread, task_args_release(task))
end


local function task_step(task)
    return handle_reply(task, task_resume(task))
end


local function step_ready_task(sched)
    local t = dqueue_pop_front("_tnext", "_tprev", sched._q_ready)
    if not t then
        return false
    end
    sched._running = t
    task_step(t)
    sched._running = false
    return true
end


local function scheduler_step(sched, num_steps)
    dqueue_splice("_tnext", "_tprev", sched._q_ready, sched._q_yield)
    if num_steps and num_steps > 0 then
        while num_steps > 0 and step_ready_task(sched) do
            num_steps = num_steps - 1
        end
    else
        repeat
            local hasmore = step_ready_task(sched)
        until hasmore
    end
    dqueue_splice("_tnext", "_tprev", sched._q_ready, sched._q_yield)
    return sched._num_tasks
end


local function task_reply_yield()
    return co_yield(0)
end


local function task_reply_cancel()
    return co_yield(1)
end


local function task_reply_block(...)
    return co_yield(2, ...)
end


local function task_add_callback(task, func)
    if task_is_finished(task) then
        return task_handle_late_result(task)
    end

    local cblist = task._callbacks

    if cblist then
        cblist[func] = true
    else
        task._callbacks = { func = true }
    end
end


local function task_del_callback(task, func)
    local cblist = task._callbacks
    if cblist then
        task._callbacks[func] = nil
    end
end


local function assert_current(task)
    local co = co_running()
    if not co then
        error("Not a coroutine")
    end
    if co ~= task._thread then
        error(string.format("Not a current task %s ~= %s", co, task._thread))
    end
end


local function assert_not_current(task)
    local co = co_running()
    if not co then
        return
    end
    if co == task._thread then
        error("Attempt to unblock current task: " .. tostring(task))
    end
end


local function task_iscurrent(task)
    return co_running() == task._thread
end


local function task_block(task)
    if not task_iscurrent(task) then
        return task_do_block(task)
    end
    return task_reply_block()
end


local function task_unblock(task, ...)
    assert_not_current(task)
    return task_do_unblock(task, pack(...))
end


local function task_cancel(task)
    if not task_iscurrent(task) then
        return task_do_cancel(task)
    end
    return task_reply_cancel()
end


local function task_yield(task)
    assert_current(task)
    return task_reply_yield()
end


local function task_scheduler(task)
    return task._sched
end


local task_mt = {
    __name = "task.instance",
    __tostring = ud_tostring,
    __index = {
        status = task_status,
        iscurrent = task_iscurrent,
        block = task_block,
        fn = task_add_callback,
        delfn = task_del_callback,
        unblock = task_unblock,
        cancel = task_cancel,
        yield = task_yield,
        scheduler = task_scheduler,
    },
}


local function new_task(func, args)
    local t = {
        _thread = co_create(func),
        _args = args,
        _callbacks = false,
        _status = "",
        _tnext = false,
        _tprev = false,
        _wnext = false,
        _wprev = false,
        _blocked_on = false,
    }

    t._tnext = t
    t._tprev = t
    t._wnext = t
    t._wprev = t

    return setmetatable(t, task_mt)
end


local function scheduler_spawn(sched, func, ...)
    local t = new_task(func, pack(...))
    dqueue_push_back("_tnext", "_tprev", sched._q_ready, t)
    sched._num_tasks = sched._num_tasks + 1
    sched._num_ready = sched._num_ready + 1
    return t
end


local function scheduler_current(sched)
    local t = sched._running
    if not t then
        return nil
    end
    return t
end


local function _maybe_cancel_current(sched)
    local t = sched._running
    if t then
        if t._co == co_running() then
            return true
        else
            task_do_cancel(t)
            return false
        end
    end
end


local function _maybe_cancel_queue(sched, q, limit)
    local task = dqueue_pop_front("_tnext", "_tprev", q)
    while task do
        sched._num_ready = sched._num_ready - limit
        task_do_cancel(task)
        task = dqueue_pop_front("_tnext", "_tprev", q)
    end
end


local function scheduler_shutdown(sched)
    local was_running = _maybe_cancel_current(sched)
    local limit = was_running and 1 or 0
    while sched._num_tasks > limit do
        while sched._num_ready > 0 do
            _maybe_cancel_queue(sched, sched._q_ready, 1)
        end
        _maybe_cancel_queue(sched, sched._q_blocked, 0)
    end
end


local function scheduler_nblocked(sched)
    return sched._num_tasks - sched._num_ready
end


local function scheduler_nready(sched)
    return sched._num_ready
end


local function scheduler_ntasks(sched)
    return sched._num_tasks
end


local scheduler_mt = {
    __name = "task.scheduler",
    __tostring = ud_tostring,
    __index = {
        current = scheduler_current,
        spawn = scheduler_spawn,
        step = scheduler_step,
        shutdown = scheduler_shutdown,
        ntasks = scheduler_ntasks,
        nready = scheduler_nready,
        nblocked = scheduler_nblocked,
    },
}


local function new_scheduler()
    local t = {
        _q_ready = dqueue_init("_tnext", "_tprev", {}),
        _q_blocked = dqueue_init("_tnext", "_tprev", {}),
        _q_yield = dqueue_init("_tnext", "_tprev", {}),
        _running_task = false,
        _num_task = 0,
        _num_ready = 0,
        _tasks = {},
    }

    return setmetatable(t, scheduler_mt)
end


local function current_scheduler()
    local t = current_task()
    if not t then
        return nil
    end
    return t:schedulder()
end


local function spawn(func, ...)
    local sched = current_scheduler()
    if not sched then
        error("No current scheduler")
    end
    return sched:spawn(func, ...)
end


local function waitlist_wakeup(obj, args)
    local val = dqueue_pop_front("_wnext", "_wpref", obj)
    while val ~= obj do
        task_do_unblock(val, args)
        val = dqueue_pop_front("_wnext", "_wpref", obj)
    end
end


local function waitlist_wakeup_one(obj, args)
    local val = dqueue_pop_front("_wnext", "_wpref", obj)
    task_do_unblock(val, args)
    val = dqueue_pop_front("_wnext", "_wpref", obj)
end


local function waitlist_cancel(obj)
    local val = dqueue_pop_front("_wnext", "_wpref", obj)
    while val ~= obj do
        task_do_cancel(val)
        val = dqueue_pop_front("_wnext", "_wpref", obj)
    end
end


local function waitlist_block_on(obj)
    dqueue_push_back("_wnext", "_wpref", obj, assert_current_task())
    return task_reply_block()
end


EVENT_STATE = {
    [-1] = "cancelled",
    [0] = "init",
    [1] = "posted",
}


local function event_post(event, ...)
    if event._state ~= 0 then
        error("Attempt to post fired event")
    end
    local args = pack(...)
    event._args = args
    waitlist_wakeup(event, args)
end


local function event_wait(event)
    if event._state == -1 then
        return task_reply_cancel()
    end
    if event._state == 1 then
        return vararg_unpack_n(event._args)
    end
    return waitlist_block_on(event)
end


local function event_cancel(event)
    event._state = -1
    waitlist_cancel(event)
end


local function event_reset(event)
    event._state = -1
    waitlist_cancel(event)
    event._state = 0
    event._args = pack()
end


local function event_state(event)
    return EVENT_STATE[event._state]
end


local event_mt = {
    __name = "task.event",
    __tostring = ud_tostring,
    __index = {
        post = event_post,
        wait = event_wait,
        cancel = event_cancel,
        reset = event_reset,
        state = event_state,
    }
}


local function new_event()
    local t = {
        _wnext = false,
        _wprev = false,
        _args = pack(),
        _state = 0,
    }
    t._wnext = t
    t._wprev = t
    return setmetatable(t, event_mt)
end


local function _max(a, b)
    if b < a then
        return a
    end
    return b
end


local function posint(value)
    if not value then
        return 0
    end
    local n = tonumber(value)
    return n > 0 and n - n % 1 or 0
end


local function sem_post(sem, value, maxvalue)
    local state = sem._state
    if state < 0 then
        return -1
    end

    local v = posint(value)
    if v <= 0 then
        return state
    end

    local mv = posint(maxvalue)
    if mv > 0 then
        state = _max(state + v, mv)
    else
        state = state + v
    end

    while state > 0 do
        local t = dqueue_pop_front("_wnext", "_wpref", sem)
        if t == sem then
            break
        end
        state = state - 1
        task_do_unblock(t, 1)
    end

    sem._state = state

    return state
end


local function sem_wait(sem)
    local state = sem._state
    if state < 0 then
        return task_reply_cancel()
    end
    if state == 0 then
        return task_reply_block()
    end
    state = state - 1
    sem._state = state
    return state
end


local function sem_cancel(sem)
    sem._state = -1
    waitlist_cancel(sem)
end


local function sem_reset(sem)
    sem._state = -1
    waitlist_cancel(sem)
    sem._state = 0
end


local function sem_state(sem)
    return sem._state
end


local sem_mt = {
    __name = "task.semaphore",
    __tostring = ud_tostring,
    __index = {
        post = sem_post,
        wait = sem_wait,
        cancel = sem_cancel,
        reset = sem_reset,
        state = sem_state,
    }
}


local function new_sem(state)
    local t = {
        _wnext = false,
        _wprev = false,
        _state = posint(state),
    }
    t._wnext = t
    t._wprev = t
    return setmetatable(t, sem_mt)
end


local function rq_push(q, value)
    if q.n == q.c then
        return false
    end

    q.n = q.n + 1
    local idx = (q.w + 1) % q.c
    q.w = idx
    q[idx + 1] = value

    return true
end


local function rq_pop(q)
    if q.n == 0 then
        return nil
    end

    q.n = q.n - 1
    local idx = (q.r + 1) % q.c
    q.r = idx

    return q[idx + 1]
end


local function bqueue_post(bqueue, value)
    while bqueue._q do
        if rq_push(bqueue._q, value) then
            return
        end
        waitlist_block_on(bqueue._w)
    end

    if not bqueue._q then
        if current_task() then
            task_reply_cancel()
        else
            error("Attempt to post in closed queue")
        end
    end
end


local function bqueue_wait(bqueue)
    while bqueue._q do
        local value = rq_pop(bqueue._q)
        if value ~= nil then
            return value
        end
        waitlist_block_on(bqueue._r)
    end
    task_reply_cancel()
end


local function bqueue_cancel(bqueue)
    bqueue._q = nil
    waitlist_cancel(bqueue._q)
end


local bqueue_mt = {
    __name = "task.bounded_queue",
    __tostring = ud_tostring,
    __index = {
        post = bqueue_post,
        wait = bqueue_wait,
        cancel = bqueue_cancel,
    }
}


local function new_bqueue(capacity)
    local t = {
        _q = { r = 0, w = 0, c = _max(posint(capacity), 1), n = 0, },
        _r = { _wnext = false, _wprev = false },
        _w = { _wnext = false, _wprev = false },
    }

    t._r._wnext = t._r
    t._r._wprev = t._r
    t._w._wnext = t._w
    t._w._wprev = t._w

    return setmetatable(t, bqueue_mt)
end


local function alq_new()
    return {
        h = 0,
        t = 0,
        f = 0,
        n = 0,
    }
end


local function alq_init0(q)
    q.h = 0
    q.t = 0
    q.n = 0
    q.f = 0
end


local function alq_init1(q, value)
    q.h = 1
    q.t = 1
    q.n = 1
    q.f = 0
    q[1] = 0
    q[2] = value
end


local function alq_push(q, value)
    if value == nil then
        error("Expected value, got: " .. tostring(value))
    end
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


local function alq_pop(q)
    if q.n == 0 then
        return nil
    end

    q.n = q.n - 1

    if q.n == 0 then
        local v = q[q.h + 1]
        q[q.h + 1] = false
        alq_init0(q)
        return v
    end

    local idx_head = q.h
    local idx_next = q[idx_head]
    q[idx_head] = q.f
    q.h = idx_next

    local v = q[idx_head + 1]
    q[idx_head + 1] = false

    return v
end


local function uqueue_post(uqueue, value)
    if not uqueue._q then
        error("Attempt to push after cancel")
    end
    alq_push(uqueue._q, value)
    waitlist_wakeup_one(uqueue, false)
end


local function uqueue_wait(uqueue)
    while uqueue._q do
        local value = alq_pop(uqueue._q)
        if value ~= nil then
            return value
        end
        waitlist_block_on(uqueue)
    end
    task_reply_cancel()
end


local function uqueue_cancel(uqueue)
    uqueue._q = nil
    waitlist_cancel(uqueue)
end


local uqueue_mt = {
    __name = "task.undbounded_queue",
    __tostring = ud_tostring,
    __index = {
        post = uqueue_post,
        wait = uqueue_wait,
        cancel = uqueue_cancel,
    }
}


local function new_uqueue()
    local t = {
        _q = alq_new(),
        _wnext = false,
        _wprev = false,
    }

    t._r._wnext = t._r
    t._r._wprev = t._r
    t._w._wnext = t._w
    t._w._wprev = t._w

    return setmetatable(t, uqueue_mt)
end


return {
    new_scheduler = new_scheduler,
    scheduler = current_scheduler,
    spawn = spawn,
    event = new_event,
    sem = new_sem,
    bqueue = new_bqueue,
    uqueue = new_uqueue,
    current = current_task,
    yield = task_reply_yield,
    block = task_reply_block,
    cancel = task_reply_cancel,
}
