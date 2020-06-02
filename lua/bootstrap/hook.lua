--- Hook at main plugin events
--

local STARTUP_HOOK = {}

local SOURCE_HOOK = {}
local FILETYPE_HOOK = {}
local COMMAND_HOOK = {}
local FUNCTION_HOOK = {}
local BUFFER_NEW_HOOK = {}
local BUFFER_READ_HOOK = {}
local BUFFER_ENTER_HOOK = {}
local USER_HOOK = {}

local SOURCE_ONCE = {}
local FILETYPE_ONCE = {}
local COMMAND_ONCE = {}
local FUNCTION_ONCE = {}
local BUFFER_NEW_ONCE = {}
local BUFFER_READ_ONCE = {}
local BUFFER_ENTER_ONCE = {}
local USER_ONCE = {}



local expand = vim.fn.expand



local function append(hook, key, fun)
    local h = hook[key]
    if h ~= nil then
        table.insert(h, fun)
    else
        hook[key] = {fun}
    end
end


local function fnmatch(path)
    return function(pattern)
        return string.match(path, pattern)
    end
end


local function extract_if(hook, pred, default)
    for key, value in pairs(hook) do
        if pred(key) then
            hook[key] = nil
            return value
        end
    end
    return default
end


local function find_if(hook, pred, default)
    for key, value in pairs(hook) do
        if pred(key) then
            return value
        end
    end
    return default
end


local function extract(hook, key, default)
    local value = hook[key]
    if value ~= nil then
        hook[key] = nil
        return value 
    end
    return default
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


local function hook_on_source()
    local opts = { file = expand("<afile>") }
    call(extract_if(SOURCE_ONCE, fnmatch(opts.file)), opts)
    call(find_if(SOURCE_HOOK, fnmatch(opts.file)), opts)
end


local function hook_on_startup()
    local opts = nil
    call(STARTUP_HOOK, opts)
    STARTUP_HOOK = nil
end


local function hook_on_filetype()
    local opts = { file = expand("<afile>"), match = expand("<amatch>") }
    call(extract(FILETYPE_ONCE, opts.match), opts)
    call(FILETYPE_HOOK[opts.match], opts)
end


local function hook_on_function()
    local opts = { match = expand("<amatch>") }
    call(extract(FILETYPE_ONCE, opts.match), opts)
    call(FUNCTION_HOOK[opts.match], opts)
end


local function hook_on_command()
    local opts = { match = expand("<amatch>") }
    call(extract_if(COMMAND_ONCE, fnmatch(opts.match)), opts)
    call(find_if(COMMAND_HOOK, fnmatch(opts.match)), opts)
end


local function hook_on_bufnew()
    local opts = { file = expand("<afile>") }
    call(extract_if(BUFFER_NEW_ONCE, fnmatch(opts.file)), opts)
    call(find_if(BUFFER_NEW_HOOK, fnmatch(opts.file)), opts)
end


local function hook_on_bufread()
    local opts = { file = expand("<afile>") }
    call(extract_if(BUFFER_READ_ONCE, fnmatch(opts.file)), opts)
    call(find_if(BUFFER_READ_HOOK, fnmatch(opts.file)), opts)
end


local function hook_on_bufenter()
    local opts = { file = expand("<afile>") }
    call(extract_if(BUFFER_ENTER_ONCE, fnmatch(opts.file)), opts)
    call(find_if(BUFFER_ENTER_HOOK, fnmatch(opts.file)), opts)
end

local function hook_on_user()
    local opts = { file = expand("<afile>"), match = expand("<amatch>") }
    call(extract_if(USER_ONCE, fnmatch(opts.match)), opts)
    call(find_if(USER_HOOK, fnmatch(opts.match)), opts)
end


local function loaded()
    return _loaded_vim
end


local function on_startup(fun)
    if vim.v.vim_did_enter then
        fun()
    else
        table.insert(STARTUP_HOOK, fun)
    end
end


local function on_source(pattern, fun)
    for _, file in ipairs(loaded()) do
        if string.match(file, pattern) then
            fun({ file = file })
        end
    end
    append(SOURCE_HOOK, pattern, fun)
end


local function on_filetype(ft, fun)
    append(FILETYPE_HOOK, ft, fun)
end


local function on_command(cmdname, fun)
    append(COMMAND_HOOK, cmdname, fun)
end


local function on_function(funname, fun)
    append(FUNCTION_HOOK, funname, fun)
end


local function on_bufnew(pat, fun)
    append(BUFFER_NEW_HOOK, pat, fun)
end


local function on_bufread(pat, fun)
    append(BUFFER_READ_HOOK, pat, fun)
end

local function on_bufenter(pat, fun)
    append(BUFFER_ENTER_HOOK, pat, fun)
end


local function on_user(pat, fun)
    append(USER_HOOK, pat, fun)
end


local function on_source_once(pattern, fun)
    for _, file in ipairs(loaded()) do
        if string.match(file, pattern) then
            fun({ file = file })
            return
        end
    end
    append(SOURCE_ONCE, pattern, fun)
end


local function on_command_once(cmdname, fun)
    append(COMMAND_ONCE, cmdname, fun)
end


local function on_filetype_once(ft, fun)
    append(FILETYPE_ONCE, ft, fun)
end


local function on_function_once(funname, fun)
    append(FUNCTION_ONCE, funname, fun)
end


local function on_bufnew_once(pat, fun)
    append(BUFFER_NEW_ONCE, pat, fun)
end


local function on_bufread_once(pat, fun)
    append(BUFFER_READ_ONCE, pat, fun)
end


local function on_bufenter_once(pat, fun)
    append(BUFFER_ENTER_ONCE, pat, fun)
end


local function on_user_once(pat, fun)
    append(USER_ONCE, pat, fun)
end


local AUTOCMD = [[
augroup hook
    autocmd!
    au SourcePost *         :lua _run_hook('SourcePost')
    au FileType *?          :lua _run_hook('FileType')
    au FuncUndefined *?     :lua _run_hook('FuncUndefined')
    au CmdUndefined *?      :lua _run_hook('CmdUndefined')
    au BufRead *?           :lua _run_hook('BufRead')
    au BufNew,BufNewFile *? :lua _run_hook('BufNew')
    au BufEnter *           :lua _run_hook('BufEnter')
    au User *               :lua _run_hook('User')
augroup end
]]


local AUTOCMD_STARTUP = "au hook VimEnter * ++once :lua _run_hook('VimEnter')"


local HOOK = {
    VimEnter = hook_on_startup,
    SourcePost = hook_on_source,
    FileType = hook_on_filetype,
    FuncUndefined = hook_on_function,
    CmdUndefined = hook_on_command,
    BufRead = hook_on_bufread,
    BufNew = hook_on_bufnew,
    BufEnter = hook_on_bufenter,
    User = hook_on_user
}


function _run_hook(hook, ...)
    HOOK[hook](...)
end


vim.api.nvim_exec(AUTOCMD, false)
if vim.v.vim_did_enter ~= 1 then
    vim.api.nvim_command(AUTOCMD_STARTUP)
end


return {
    on = {
        source = on_source,
        filetype = on_filetype,
        command = on_command,
        func = on_function,
        bufnew = on_bufnew,
        bufread = on_bufread,
        bufenter = on_bufenter,
        user = on_user
    },
    after = {
        startup = on_startup,
        source = on_source_once,
        filetype = on_filetype_once,
        command = on_command_once,
        func = on_function_once,
        bufnew = on_bufnew_once,
        bufread = on_bufread_once,
        bufenter = on_bufenter_once,
        user = on_user_once,
    },
    hook = {
        on = {
            source = SOURCE_HOOK,
            filetype = FILETYPE_HOOK,
            command = COMMAND_HOOK,
            func = FUNCTION_HOOK,
            bufnew = BUFFER_NEW_HOOK,
            bufread = BUFFER_READ_HOOK,
            bufenter = BUFFER_ENTER_HOOK,
            user = USER_HOOK
        },
        after = {
            startup = STARTUP_HOOK,
            source = SOURCE_ONCE,
            filetype = FILETYPE_ONCE,
            command = COMMAND_ONCE,
            func = FUNCTION_ONCE,
            bufnew = BUFFER_NEW_ONCE,
            bufread = BUFFER_READ_ONCE,
            bufenter = BUFFER_ENTER_ONCE,
            user = USER_ONCE
        },
    }
}

--- hook.lua ends here
