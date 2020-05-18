local interop = require "bootstrap.interop"

local indent_blank_line = "\\<End>x\\<C-o>==\\<End>\\<Left>\\<Del>"
local indent = "\\<C-o>=="
local real_tab = "\\<Tab>"

local call = vim.api.nvim_call_function


local function current_line()
    return call("getline", {"."})
end


local function indent()
    if current_line():find("^%s*$") then
        vim.api.nvim_command(indent_blank_line)
    else
        vim.api.nvim_command(indent)
    end
end


local function set(name, value)
    vim.o[name] = value
end


local function setb(name, value)
    vim.o[name] = value
    vim.bo[name] = value
end


local function setup()
    local mapping = "inoremap <silent> <Tab> <C-r>=<CR>"

    setb("tabstop", 8)
    setb("softtabstop", 4)
    setb("shiftwidth", 4)
    setb("expandtab", true)
    setb("autoindent", true)
    setb("smartindent", true)
end


return {
    setup = setup,
    indent = indent
}
