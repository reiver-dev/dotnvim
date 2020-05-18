--- Basic key bindings
--

local cmd = vim.cmd


local EMACS = [[
    inoremap <C-p> <Up>
    inoremap <C-n> <Down>
    inoremap <C-f> <Right>
    inoremap <C-b> <Left>

    inoremap <C-a> <Home>
    inoremap <C-e> <End>

    inoremap <M-f> <S-Right>
    inoremap <M-b> <S-Left>

    inoremap <C-d> <Del>
    inoremap <C-h> <BS>
    inoremap <C-k> <C-\><C-o>D

    inoremap <M-d> <C-\><C-o>dw
    inoremap <M-h> <C-\><C-o>db
    inoremap <M-k> <End><C-u>
]]


local function setup()
    cmd(EMACS)
end


return {
    setup = setup
}

--- keybind.lua ends here
