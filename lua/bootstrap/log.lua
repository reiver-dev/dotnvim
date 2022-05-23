---@type file*
local file

local inspect = vim.inspect
local in_fast_event = vim.in_fast_event
local nvim_get_current_buf = vim.api.nvim_get_current_buf
local str_fmt = string.format
local concat = table.concat
local select, tostring = select, tostring

local format_date = os.date
local gettimeofday = vim.loop.gettimeofday


local function current_buffer()
    if in_fast_event() then
        return 0
    else
        return nvim_get_current_buf()
    end
end


local inspect_options = {
    indent = "    ",
    depth = math.huge,
    newline = "\n    ",
}


local function pprint(value)
    return inspect(value, inspect_options)
end


local function kvp(key, val)
    return tostring(key) .. ": " .. pprint(val)
end


local function kp(key)
    return tostring(key) .. ": <NOTSET>"
end


local function vp(val)
    return "value: " .. pprint(val)
end


local function gather_data_1(tbl, step, nargs, key, val, ...)
    if nargs > 2 then
        tbl[step] = kvp(key, val)
        gather_data_1(tbl, step + 1, nargs - 2, ...)
    elseif nargs == 2 then
        tbl[step] = kvp(key, val)
    elseif nargs == 1 then
        tbl[step] = kp(key)
    end
    return tbl
end


local function gather_data(...)
    local num = select("#", ...)
    if num == 0 then
        return nil
    elseif num == 1 then
        return {vp(select(1, ...))}
    elseif num == 2 then
        return {kvp(...)}
    end
    return gather_data_1({}, 1, num, ...)
end


local function log(message, ...)
    local sec, usec = gettimeofday()
    local datetime = format_date("%Y-%m-%d %H:%M:%S", sec)
    local bufnr = current_buffer()
    local data = gather_data(...)
    local header = str_fmt("[I %s.%06d B:%d] %s\n", datetime, usec, bufnr, message)
    if data ~= nil then
        local datamsg = concat(data, "\n    ")
        file:write(header, "    ", datamsg, "\n\n")
    else
        file:write(header, "\n")
    end
    file:flush()
end


local function setup()
    if file then
        file:close()
    end
    local log_dir = vim.fn.stdpath("log")
    local filename = log_dir .. "/my.log"
    vim.fn.mkdir(log_dir, "p")
    file = io.open(filename, "ab")
    _G.LOG = log
end


return {
    log = log,
    setup = setup,
}
