--- Configure tabline

function __Tablabel(tabid)
    local windows = vim.api.nvim_tabpage_list_wins(tabid)
    local window_count = 0
    local diff_count = 0
    for _, winid in ipairs(windows) do
        -- do not count floating widnows
        local wincfg = vim.api.nvim_win_get_config(winid)
        if wincfg.relative == "" then
            window_count = window_count + 1
        end
        -- keep track of diff buffers
        if vim.api.nvim_win_get_option(winid, "diff") then
            diff_count = diff_count + 1
        end
    end
    local components = {tostring(window_count)}
    if diff_count > 0 then
        components[#components + 1] = string.format("D(%d)", diff_count)
    end
    return table.concat(components, " ")
end


function __Tabline()
    local tabpages = vim.api.nvim_list_tabpages()
    local current_tabpage = vim.api.nvim_get_current_tabpage()
    local tabs = {}
    local fmt = string.format
    for i, tabpagenum in ipairs(tabpages) do
        local hl
        if tabpagenum == current_tabpage then
            hl = "%#TablineSel#"
        else
            hl = "%#TabLine#"
        end
        local label = fmt(" %%%dT[%s]%%T ", i, __Tablabel(tabpagenum))
        tabs[i] = fmt("%s%s", hl, label)
    end
    local fill = "%#TabLineFill#%="
    local cwd = vim.api.nvim_exec("verbose pwd", true)
    return table.concat(tabs, "%#TabLineFill# ") .. fill .. cwd
end


vim.o.tabline = "%!v:lua.__Tabline()"


--- tabline.lua ends here
