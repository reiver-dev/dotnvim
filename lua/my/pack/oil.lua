--- Configuration for oil.nvim

local normalize
if package.config:sub(1, 1) then
    normalize = function(path)
        local drive, rest = string.match(path, "^/(%a)/(.*)")
        if drive and rest then
            return drive .. ":/" .. rest
        end
        local result = string.gsub(path, "\\", "/")
        return result
    end
else
    normalize = function(path)
        return path
    end
end


local function get_path(bufname)
    local path = string.match(bufname, "^oil[-a-z]*://(.*)")
    if not path then
        return
    end
    return string.gsub(normalize(path), "/*$", "")
end


local function on_filetype(opts)
    if GETLOCAL(opts.buf, "directory") then
        return
    end
    local path = get_path(opts.file)
    if not path then
        return
    end
    require("my.directory")["force-default-directory"](opts.buf, path)
end


local function open_parent(...)
    require("oil").open(...)
end


local function setup()
    local g = vim.api.nvim_create_augroup("my-oil", { clear = true })
    vim.api.nvim_create_autocmd("FileType", {
        group = g,
        callback = on_filetype,
    })
    require"oil".setup {
        columns = {},
    }
    vim.keymap.set("n", "-", open_parent, { desc = "Open parent directory" })
end


return {
    setup = setup
}
