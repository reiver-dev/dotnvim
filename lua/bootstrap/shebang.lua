--- Shebang to filetype resolution

local function line_from_path(location)
    local file = io.open(location, "r")
    if file and file:read(2) == "#!" then
        return file:read("*l")
    end
    return ""
end


local function line_from_bufnr(bufnr)
    local line = vim.api.nvim_buf_get_lines(bufnr or 0, 0, 1, false)
    local m = string.match(line[1], "^#!(.*)")
    if m then
        return m
    else
        return ""
    end
end


local filetype_defs = {
    ['sh'] = 'sh',
    ['bash'] = 'bash',
    ['zsh'] = 'zsh',
    ['fish'] = 'fish',
    ['python'] = 'python',
    ['python2'] = 'python',
    ['python3'] = 'python',
    ['perl'] = 'perl',
}

local arg_fmts = {
    "^/bin/([^ /]+)$",
    "^/usr/bin/env +(.+)$",
    "^/usr/bin/([^ /]+)$",
    "^/bin/env +(.+)$",
}


local function filetype_from_line(line)
    if not line or line == "" then
        return
    end

    local match = string.match
    for _, fmt in pairs(arg_fmts) do
        local m = match(line, fmt)
        if m then
            line = m
            break
        end
    end

    return filetype_defs[line]
end


local function apply(bufnr)
    local ok, dft = pcall(vim.b.did_ftplugin)
    if ok and dft == 1 or vim.bo.filetype ~= "" then
        return
    end

    local filetype = filetype_from_line(line_from_bufnr(bufnr or 0))

    if filetype then
        vim.bo.filetype = filetype
    end
end


local function setup()
    vim.cmd [[
        augroup bootstrap_shebang
        autocmd!
        autocmd BufReadPost * lua require"bootstrap.shebang".apply(0)
        augroup END
    ]]
end


return {
    setup = setup,
    from_path = line_from_path,
    from_bufnr = line_from_bufnr,
    filetype_from_line = filetype_from_line,
    apply = apply,
}

--- shebang.lua ends here
