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


function M.enter(chan)
    local info = vim.api.nvim_get_chan_info(chan)
    if not (info and info.client) then
        return
    end
    if info.client.name == "nvim-qt" then
        require"bootstrap.gui.nvim_qt".configure(chan)
    end
end


function M.leave(chan)
end


function M.setup()
   vim.api.nvim_exec(au, nil) 
end


return M

--- gui/init.lua ends here
