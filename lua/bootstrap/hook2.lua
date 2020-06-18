--- Hook at main events
--


local expand_keys = {
   file = '<afile>',
   buf = '<abuf>',
   match = '<amatch>'
}


local expand = vim.fn.expand

local normalize = nil
if vim.fn.has('win32') then
    normalize = function(path)
        return path:gsub('\\', '/')
    end
else
    normalize = function(path)
        return path
    end
end


local expand_meta = {
    __index = function(self, key)
        local ekey = expand_keys[key]
        if ekey then
            local value = normalize(expand(ekey))
            if value ~= nil then
                rawset(self, key, value)
            end
            return value
        end
    end,
    __newindex = function(self, key, val)
        error("Expand table is immutable")
    end
}



local function Expand(base)
    return setmetatable(base or {}, expand_meta)
end


local function hook_data(name, match_key)
    return {
        name = name,
        handlers = {},
        every = {
            exact = {},
            match = {},
            always = {},
        },
        once = {
            exact = {},
            match = {},
            always = {},
        },
        match_key = match_key or 'file'
    }
end



local function format_error(name, func, err)
    local func = debug.getinfo(func).short_src
    local msg = string.format("Error (%s:%s): %s", name, func, err)
    return msg
end


local function pcall_many(hooks, args)
    if functions ~= nil then
        local errors = {}
        for key, hook in pairs(hooks) do
            local ok, res = pcall(hook, args)	
            if not ok then
                errors[#errors + 1] = {key, func, err}
            end
        end
        return errors
    end
    return nil
end



local function set(tbl, value, ...)
    local tbl0 = nil
    local keys = {...}
    local keylen = #keys 

    for i, k in ipairs(keys) do
        if i == keylen then
            tbl[k] = value
            return
        end

        tbl0 = tbl[k]

        if tbl0 == nil then
            tbl0 = {}
            tbl[k] = tbl0
        end

        tbl = tbl0
    end
end



local function hook_del(hook, name)
    local h = hook.handlers[name]

    if h == nil then
        return
    end

    hook.handlers[name] = nil

    local opts = h.opts
    local category = opts.once and hook.once or hook.every

    if h.key == nil or h.key == "" then
        category.always[h.key] = nil
    else
        local handlers = opts.isre and category.match or category.exact
        local htable = handlers[h.key]
        htable[h.name] = nil
        if is_empty(htable) then
            handlers[h.key] = nil
        end
    end
end


local function hook_add(hook, name, key, handler, opts)
    hook_del(hook, name)

    local category = opts.once and hook.once or hook.every

    hook.handlers[name] = {
        name = name,
        key = key,
        handler = handler,
        opts = opts
    }

    if key == nil or key == "" then
        set(category.always, handler, name)
    else
        local handlers = opts.isre and category.match or category.exact
        set(handlers, handler, key, name)
    end
end



local function call(hooks, args)
    if hooks == nil then
        return
    end

    local errors = {}

    for i, hook in ipairs(hooks) do
        local ok, res = pcall(hook, args)	
        if not ok then
            errors[#errors + 1] = {res, i}
        end
    end

    if #errors > 0 then
        local messages = {}
        for _, err in ipairs(errors) do
            local msg = string.format("Error (%s): %s",
                debug.getinfo(hooks[err[2]]).short_src, err[1])
            messages[#messages + 1] = msg
        end
        error(table.concat(messages, '\n'))
    end
end


local function is_empty(tbl)
    return next(pairs(tbl)) == nil
end


local function execute_once(hook, expand)
    local key = expand[hook.match_key]

    local to_remove_exact = nil
    local exact_match = hook.once.exact[key]
    if exact_match ~= nil then
        to_remove_exact = exact_match
        call(exact_match, expand)
    end

    local to_remove_match = {}
    for pattern, matches in pairs(hook.once.match) do
        if key:match(pattern) then
            to_remove_match[#to_remove_match + 1] = pattern
            call(matches, expand)
        end
    end

    call(hook.once.always, expand)

    if to_remove_exact then
        hook.once.exact[to_remove_exact] = nil
    end

    for _, pattern in ipairs(to_remove_match) do
        hook.once.match[pattern] = nil
    end

    hook.once.always = {}
end


local function execute_every(hook, expand)
    local key = expand[hook.match_key]

    local exact_match = hook.every.exact[key]
    if exact_match ~= nil then
        call(exact_match, expand)
    end

    local to_remove_match = {}
    for pattern, matches in pairs(hook.every.match) do
        if key:match(pattern) then
            call(matches, expand)
        end
    end

    call(hook.once.always, expand)
end


local function hook_run(hook)
    local expand = Expand()
    execute_once(hook, expand)
    execute_every(hook, expand)
end


local function method_add(hook, pred, name, handler, opts)
    vim.validate{
        hook = {hook, 'table'},
        name = {name, 'string'},
        pred = {pred, 'string'},
        handler = {handler, 'function'},
        opts = {opts, 'table', true},
    }
    hook_add(hook, name, pred, handler, opts)
end


local function method_add_startup(hook, name, handler)
    vim.validate{
        hook = {hook, 'table'},
        name = {name, 'string'},
        handler = {handler, 'function'},
    }
    if vim.v.vim_did_enter then
        handler(Expand())
    else
        hook_add(hook, name, nil, handler, { once = true })
    end
end


local function loaded()
    return require"bootstrap.loaded".loaded_vim
end


local function method_add_source(hook, key, name, handler)
    vim.validate{
        hook = {hook, 'table'},
        name = {name, 'string'},
        pred = {pred, 'string'},
        handler = {handler, 'function'},
    }

    for _, path in ipairs(loaded()) do
        if path:patch(key) then
            handler(Expand({ file = path, match = path }))
            return
        end
    end
    
    hook_add(hook, name, pred, handler, { once = true, isre = true })
end



local HOOK_MAIN_META = {
    __call = method_add
}


local HOOK_STARTUP_META = {
    __call = method_add_startup
}


local HOOK_SOURCE_META = {
    __call = method_add_source
}


local function make_hook(name, key, meta)
    return setmetatable(hook_data(name, key), meta or HOOK_MAIN_META)
end


local HOOKS = {
    startup = make_hook("VimEnter", '', HOOK_STARTUP_META),
    source = make_hook("SourcePost", '', HOOK_SOURCE_META),
    filetype = make_hook("FileType", 'match'),
    func = make_hook("FuncUndefined", 'match'),
    command = make_hook("CmdUndefined", 'match'),
    bufnew = make_hook("BufRead", 'file'),
    bufread = make_hook("BufNew", 'file'),
    bufenter = make_hook("BufEnter", 'file'),
    user = make_hook("User", 'match'),
}


function _run_hook2(name, ...)
    local h = HOOKS[name]
    if h then
        hook_run(h)
    end
end


local AUTOCMD = [[
augroup hook2
    autocmd!
    au SourcePost *         :lua _run_hook2('source')
    au FileType *?          :lua _run_hook2('filetype')
    au FuncUndefined *?     :lua _run_hook2('func')
    au CmdUndefined *?      :lua _run_hook2('command')
    au BufNew,BufNewFile *? :lua _run_hook2('bufnew')
    au BufRead *?           :lua _run_hook2('bufread')
    au BufEnter *           :lua _run_hook2('bufenter')
    au User *               :lua _run_hook2('user')
augroup end
]]

local AUTOCMD_STARTUP = "au hook2 VimEnter * ++once :lua _run_hook2('startup')"


vim.api.nvim_exec(AUTOCMD, false)
if vim.v.vim_did_enter ~= 1 then
    vim.api.nvim_command(AUTOCMD_STARTUP)
end


local function export_hook()
    local mod = { hooks = HOOKS }
    for name, hook in pairs(HOOKS) do
        mod[name] = function(...)
            hook(...)
        end
    end
    return mod
end


return export_hook()
