local function setup()
    vim.o.termguicolors = true

    vim.cmd [[
        function! ClipboardReset()
            unlet! g:loaded_clipboard_provider
            runtime autoload/provider/clipboard.vim
        endfunction
    ]]

    require("bootstrap.log").setup()
    require("bootstrap.idle").setup()
    -- Download package manager and friends
    require("bootstrap.basedeps").setup()
    require("bootstrap.modules").setup()
    require("bootstrap.fennel").setup()
    require("bootstrap.trampouline").setup()
    require("bootstrap.reload").setup()
    -- require("bootstrap.gui").setup()
    require("bootstrap.eval").setup()
    require("my").setup()
end


return {setup = setup}
