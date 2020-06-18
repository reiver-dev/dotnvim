local interop = require "bootstrap.interop"


local function set(name, value)
    vim.api.nvim_set_option(name, value)
end


local function setw(name, value)
    vim.o[name] = value
    vim.wo[name] = value
end


local function setb(name, value)
    vim.o[name] = value
    vim.bo[name] = value
end


local function setup()
    if vim.o["compatible"] then
        vim.api.nvim_command("set nocompatible")
    end

    setw("number", true)
    setw("relativenumber", true)
    setb("textwidth", 79)

    set("clipboard", "unnamedplus")
    set("mouse", "a")
    set("termguicolors", true)
    set("autochdir", true)
    set("shortmess", "Ic")
    set("undofile", true)
    set("showtabline", 2)
    set("hidden", true)
    set("completeopt", "menuone,noinsert,noselect")

    vim.api.nvim_command("let mapleader=\",\"")
    vim.api.nvim_command("let maplocalleader=\";\"")
    vim.api.nvim_command("nnoremap <leader><leader> :b#<CR>")
end

return {
    setup = setup
}
