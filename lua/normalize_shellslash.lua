-- Normalize path separator on Windows

local function normalize_oldfiles()
    local from = "/"
    local to = "\\"

    local oldfiles = vim.v.oldfiles
    local new = {}
    local set = {}
    local t = 1
    local gsub = string.gsub

    for i = 1, #oldfiles do
        local path = gsub(oldfiles[i], from, to)
        local exists = set[path]
        if not exists then
            set[path] = true
            new[t] = path
            t = t + 1
        end
    end

    vim.v.oldfiles = new
end


local function normalize_shellslash()
    _G.SHELLSLASH = vim.o.shellslash
    normalize_oldfiles()
end


local function setup()
    local g = vim.api.nvim_create_augroup("boostrap-shellslash", { clear = true, })
    if vim.v.vim_did_enter == 0 then
        vim.api.nvim_create_autocmd("VimEnter", {
            group = g,
            once = true,
            callback = normalize_shellslash,
        })
    end
    vim.api.nvim_create_autocmd("OptionSet", {
        pattern = 'shellslash',
        group = g,
        callback = normalize_shellslash,
    })

    _G.SHELLSLASH = vim.o.shellslash
end


return {
    setup = setup,
    normalize_shellslash = normalize_shellslash,
}
