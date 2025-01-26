local getlocal, setlocal
do
    local br = require "bufreg"
    getlocal = br.getlocal
    setlocal = br.setlocal
end

local vim_getcwd = vim.fn.getcwd
local vim_fnamemodify = vim.fn.fnamemodify
local str_match = string.match
local str_gsub = string.gsub

local nvim_exec_autocmds = vim.api.nvim_exec_autocmds
local nvim_get_current_buf = vim.api.nvim_get_current_buf
local nvim_buf_get_option = vim.api.nvim_buf_get_option
local nvim_buf_is_loaded = vim.api.nvim_buf_is_loaded
local nvim_buf_get_var = vim.api.nvim_buf_get_var
local nvim_buf_set_var = vim.api.nvim_buf_set_var
local nvim_buf_call = vim.api.nvim_buf_call
local nvim_cmd = vim.api.nvim_cmd

local hook = {}

local function add_hook(name, fun)
    hook[name] = fun
end

local function remove_hook(name)
    hook[name] = nil
end

local function call_hook(bufnr, directory)
    for _, fun in pairs(hook) do
        fun(bufnr, directory)
    end
end

local normalize
do
    if package.config:sub(1, 1) == "\\" then
        function normalize(path)
            local r = str_gsub(path, "\\", "/")
            return r
        end
    else
        function normalize(path)
            return path
        end
    end
end

local normalize_cygwin
if "\\" == package.config:sub(1, 1) then
    function normalize_cygwin(path)
      local drive, rest = str_match(path, "^/(%a)/(.*)")
      if drive and rest then
          return drive .. ":/" .. rest
      end
      return normalize(path)
    end
else
    function normalize_cygwin(path)
        return path
    end
end

local function getcwd()
    return normalize(vim_getcwd())
end

local _cd_arg = {
    cmd = "lcd",
    args = {""},
    magic = {
        file = false
    },
}

local _Empty = {}

local function setcwd(path)
    _cd_arg.args[1] = path
    nvim_cmd(_cd_arg, _Empty)
end

local function fs_dirname(name)
    return vim.fs.dirname(name)
end

local function term_dirname(name)
    return normalize(
        vim_fnamemodify(
            str_match(name, "^[a-z][a-z]+://(.+)//[0-9]+:"),
            ":p"
        )
    )
end

local function fugitive_dirname(name)
    return vim.fs.dirname(
        vim.uri_to_fname(
            str_gsub(name, "^fugitive://(.+)//.*$", "file://%1")
        )
    )
end

local function oil_dirname(name)
    return str_gsub(
        normalize_cygwin(
            str_match(name, "oil://(.*)")
        ),
        "/*$",
        ""
    )
end

local function uri_dirname(name)
    return normalize(vim.fs.dirname(vim.uri_to_fname(name)))
end

local SchemeHandlers = {
    ["term:"] = term_dirname,
    ["fugitive:"] = fugitive_dirname,
    ["file:"] = uri_dirname,
    ["oil:"] = oil_dirname,
}

local function extract_dirname(name)
    local scheme = str_match(name, "^[a-z][a-z]+:")
    if not scheme then
        return fs_dirname(name)
    end
    local handler = SchemeHandlers[name]
    if handler then
        return handler(name)
    end
end

local ValidBuftypes = {
    [""] = true,
    nowrite = true,
    acwrite = true,
    help = true,
}

local function is_buftype_valid(bufnr)
    return ValidBuftypes[nvim_buf_get_option(bufnr, "buftype")]
end

local function is_directory(path)
    if not path or path == "" then
        return false
    end
    local res = vim.loop.fs_stat(path)
    return res and res.type == "directory"
end

local function getbufvar(bufnr, name)
    local ok, res = pcall(nvim_buf_get_var, bufnr or 0, name)
    if ok then return res end
    return ""
end

local function setbufvar(bufnr, name, value)
    nvim_buf_set_var(bufnr or 0, name, value)
end

local function set_default_directory(bufnr, path)
    setlocal(bufnr, "directory", path)
    setbufvar(bufnr, "default_directory", path)
end

local function default_directory(bufnr)
    local dd = getlocal(bufnr, "directory")
    if dd then return dd end
    return getbufvar(bufnr, "default_directory")
end

local function fire_user_event(bufnr, event, data)
    nvim_exec_autocmds("User", {
        pattern = event,
        modeline = false,
        data = data
    })
end

local function fire_default_directory_updated(bufnr, new, old)
    call_hook(bufnr, new)
    fire_user_event(bufnr, "DefaultDirectory", {
        buf = bufnr,
        new = new,
        old = old
    })
end

local function apply_default_directory(bufnr, dirname)
    local dd = default_directory(bufnr)
    if bufnr == nvim_get_current_buf() then
        local dir = dirname or getcwd()
        if dir ~= dd then
            set_default_directory(bufnr, dir)
            fire_default_directory_updated(bufnr, dir, dd)
        end
    else
        if dirname and dirname ~= dd then
            set_default_directory(bufnr, dirname)
        end
    end
end

local function force_default_directory(bufnr, directory)
    local dd = default_directory(bufnr)
    nvim_buf_call(bufnr, function()
        set_default_directory(bufnr, directory)
        if directory ~= dd then
            fire_default_directory_updated(bufnr, directory)
        end
    end)
end

local function on_file_enter(opts)
    local dd = default_directory(opts.buf)
    if dd and dd ~= "" then
        local cwd = getcwd()
        if dd ~= cwd and is_directory(dd) then
            setcwd(dd)
            setlocal(opts.buf, "chdir", dd)
        end
    end
end

local function on_file_open(opts)
    if opts and is_buftype_valid(opts.buf) and nvim_buf_is_loaded(opts.buf) then
        local bufnr = opts.buf
        local file = normalize(opts.match)
        local oldfile = getlocal(bufnr, "file")
        if oldfile == nil or oldfile ~= file then
            setlocal(bufnr, "file", file)
            local dirname
            if file and file ~= "" then
                dirname = extract_dirname(file)
            end
            apply_default_directory(bufnr, dirname)
        end
    end
end

local function on_file_write(opts)
    on_file_open(opts)
    on_file_enter(opts)
end

local function on_file_rename(opts)
    on_file_open(opts)
    on_file_enter(opts)
end

local function on_chdir_memoize(opts)
    setlocal(opts.buf, "chdir", opts.file)
end

local function setup()
    local g = vim.api.nvim_create_augroup("projectile", {clear = true})
    local au = vim.api.nvim_create_autocmd
    au(
        {"VimEnter", "BufNew", "BufNewFile", "BufReadPre"},
        {group = g, callback = on_file_open, desc = "directory::on-file-open"}
    )
    au(
        {"BufEnter", "BufReadPost"},
        {group = g, callback = on_file_enter, desc = "directory::on-file-enter"}
    )
    au(
        {"DirChangedPre"},
        {group = g, callback = on_chdir_memoize, desc = "directory::on-chdir-memoize"}
    )
    au(
        {"BufWritePost"},
        {group = g, callback = on_file_write, desc = "directory::on-file-write"}
    )
    au(
        {"BufFilePost"},
        {group = g, callback = on_file_rename, desc = "directory::on-file-rename"}
    )
end

return {
    setup = setup,

    on_file_enter = on_file_enter,
    on_file_open = on_file_open,
    on_file_write = on_file_write,
    on_file_rename = on_file_rename,
    getcwd = getcwd,
    setcwd = setcwd,
    force_default_directory = force_default_directory,
    default_directory = default_directory,
    add_hook = add_hook,
    remove_hook = remove_hook,

    ["on-file-enter"] = on_file_enter,
    ["on-file-open"] = on_file_open,
    ["on-file-write"] = on_file_write,
    ["on-file-rename"] = on_file_rename,
    ["force-default-directory"] = force_default_directory,
    ["default-directory"] = default_directory,
    ["add-hook"] = add_hook,
    ["remove-hook"] = remove_hook,
}
