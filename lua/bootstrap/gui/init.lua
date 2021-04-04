--- Gui client configuration
--

local au = [[
augroup BootstrapUi
autocmd!
autocmd UIEnter * call v:lua._trampouline("bootstrap.gui", "enter", v:event['chan'])
autocmd UILeave * call v:lua._trampouline("bootstrap.gui", "leave", v:event['chan'])
augroup END
]]

local M = {}


M._pending_configuration = {}


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


function M.execute_after(info)
    local ok, mod = pcall(function() return require"after.gui" end)
    if ok and mod.setup then
        mod.setup(info)
    end
end


function M.configure()
    for _, chan in ipairs(M._pending_configuration) do
        local info = client_info(chan)
        if info then
            if handle_gui_info(info) then
                M.execute_after(info)
            end
        end
    end
    M._pending_configuration = {}
end


function M.setup()
   vim.api.nvim_exec(au, nil) 
end


return M

--- gui/init.lua ends here
