--- Gui client configuration
--

local au = [[
augroup BootstrapUi
autocmd!
autocmd UIEnter * call v:lua._T("bootstrap.gui", "enter", v:event['chan'])
autocmd UILeave * call v:lua._T("bootstrap.gui", "leave", v:event['chan'])
augroup END
]]

local M = {}


M._pending_configuration = {}
M._after_hook = {}


local function execute_hook(hook, arg)
    local errors = {}
    for name, f in pairs(hook) do
        local ok, msg = xpcall(function() return f(arg) end, debug.traceback)
        if not ok then
            errors[name] = msg
        end
    end
    if LOG then
        LOG("Failed to run after gui hook", "errors", errors)
    end
end


local function client_info(chan)
    local info = vim.api.nvim_get_chan_info(chan)
    if info and info.client and info.client.type then
        return info
    end
end


local function handle_gui_info(info)
    if info.client.name == "nvim-qt" then
        require"bootstrap.gui.nvim_qt".configure(info.id)
        return true
    elseif info.client.name == "FVim" then
        require"bootstrap.gui.fvim".configure(info.id)
        return true
    end
    return false
end


local function append(arr, val)
    arr[#arr + 1] = val
end


function M.enter(chan)
    vim.g.bootstrap_last_ui_enter = chan
    if chan == 0 then
        return
    end
    local info = client_info(chan)
    if info then
        handle_gui_info(info)
    else
        append(M._pending_configuration, chan)
    end
end


function M.leave(chan)
    vim.g.bootstrap_last_ui_leave = chan
end


function M.configure()
    for _, chan in ipairs(M._pending_configuration) do
        local info = client_info(chan)
        if info then
            handle_gui_info(info)
            execute_hook(M._after_hook, info)
        end
    end
    M._pending_configuration = {}
end


function M.setup()
   vim.api.nvim_exec(au, nil)
end


function M.hook(name, func)
    M._after_hook[name] = func
end


return M

--- gui/init.lua ends here
