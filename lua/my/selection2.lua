local _MODULE = ...
local maxcol = vim.v.maxcol

local min, max = math.min, math.max

local function block_width(start, finish)
    local lines = vim.fn.getregionpos(start, finish, {
        type = "V", exclusive = false, eol = true
    })
    local max_width = 0
    for _, line in ipairs(lines) do
        max_width = max(line[2][3], max_width)
    end
    return max_width - min(start[3], finish[3])
end

local function visual_region_range()
    local mode = vim.fn.mode()
    local isblock = string.byte(mode) == 22

    local start = vim.fn.getpos("v")
    local finish

    if isblock then
        finish = vim.fn.getcurpos()
        local curswant = finish[5]
        finish[5] = nil
        if curswant == maxcol then
            mode = string.format("%s%d", mode, block_width(start, finish))
        end
    else
        finish = vim.fn.getpos('.')
    end

    return start, finish, mode
end

local function visual_region()
    local start, finish, mode = visual_region_range()
    return vim.fn.getregion(start, finish, { type = mode })
end

local _Visual

local function memorize_visual_point()
    _Visual = visual_region()
end

local _Command = vim.api.nvim_replace_termcodes(
    string.format(
        [[silent keepjumps normal! gv<Cmd>call v:lua._T("%s", "_visual_selection_hook")<CR><Esc>]],
        _MODULE
    ),
    true, true, true
)
local _CommandOpts = {output = false}

local function should_jump(a, b)
    return not (
        a[1] ~= b[1]
        or a[2] == b[2]
        and a[3] == b[3]
        and a[4] == b[4]
    )
end

local function restore_cursor(cursor)
    local new_cursor = vim.fn.getcurpos()
    if should_jump(cursor, new_cursor) then
        vim.fn.cursor({cursor[2], cursor[3], cursor[4]})
    end
end

local function normal_region()
    local cursor = vim.fn.getcurpos()
    _Visual = nil
    vim.api.nvim_exec2(_Command, _CommandOpts)
    local res = _Visual
    _Visual = nil
    restore_cursor(cursor)
    return res
end

local visualmode = {
    [118] = true,
    [86] = true,
    [22] = true,
}

local function region()
    local mode = string.byte(vim.api.nvim_get_mode().mode)

    if visualmode[mode] then
        return visual_region()
    end

    return normal_region()
end


return {
    region = region,
    _visual_selection_hook = memorize_visual_point,
}
