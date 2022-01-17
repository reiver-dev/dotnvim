local root = vim.fn.stdpath("config")
local name = "ginit.lua"
local path = root .. package.config:sub(1, 1) .. name
local level = vim.log.levels.WARN

local function load_ui_source()
    local fd, err, errno = io.open(path, 'r')

    if fd == nil then
        if errno == 2 then
            local fd = io.open(path, "w")
            if fd then
                local t = "--- Ui config\n\n\n--- ginit.lua ends here\n"
                pcall(fd.write, fd, t)
                fd:close()
            end
        else
            vim.notify(err:gsub("\t", "    "), level)
        end
        return
    end

    local ok, text = pcall(fd.read, fd, "*all")
    fd:close()

    if ok ~= true then
        return
    end

    local mod, err = loadstring(text, "@" .. path)
    if mod == nil then
        vim.notify(err:gsub("\t", "    "), level)
        return
    end

    return mod
end


function __Init_ui(info)
    local mod = load_ui_source()
    if not mod then
        return
    end
    info = info or vim.v.event.info
    if info and info.client and info.client.type == "ui" then
        local ok, err = xpcall(function() mod(info) end, debug.traceback)
        if not ok then
            local opt = { indent = "    ", newline = "\n    " }
            local msg = string.format(
                "Failed to initialize ui:\n%s%s\n%s%s",
                opt.indent,
                vim.inspect(info, opt),
                opt.indent,
                err:gsub("\t", opt.indent):gsub("\n", opt.newline))
            vim.notify(msg, level)
        end
    end
end


local ok, err = xpcall(function()
    local mod = load_ui_source()
    if mod then
        for _, chan_info in ipairs(vim.api.nvim_list_chans()) do
            if (chan_info
                and chan_info.client
                and chan_info.client.type == "ui")
            then
                mod(chan_info)
            end
        end
    end
end, debug.traceback)

if not ok then
    vim.notify(err:gsub("\t", "    "), level)
end

vim.cmd "autocmd ChanInfo * lua __Init_ui()"
