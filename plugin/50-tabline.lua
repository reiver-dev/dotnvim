--- Configure tabline


local sep = package.config:sub(1, 1) == "\\" and "[\\/]+" or "/+"
local HOME = "^" .. string.gsub(vim.pesc(vim.env.HOME), sep, sep)


local function replacehome(path)
    return string.gsub(path, HOME, "~")
end


local function highlighted(hl, body)
    return string.format("%%#%s#%s%%#StatusLine#", hl, body)
end


local function current_mode()
    local m = require "statusline.mode"
    local mode = vim.api.nvim_get_mode().mode
    local s = m.mode_to_symbol[mode]
    return highlighted("StatusMode" .. s[1], " " .. s[2] .. " ")
end


local function setup_highlights()
    local base = vim.api.nvim_get_hl_by_name("StatusLine", true)
    local colors = require "statusline.colors"
    local modes = {
        ["Normal"] = colors.default.red,
        ["Visual"] = colors.default.blue,
        ["Insert"] = colors.default.green,
        ["Command"] = colors.default.magenta,
        ["Prompt"] = colors.default.cyan,
        ["Select"] = colors.default.orange,
        ["Replace"] = colors.default.violet,
        ["Terminal"] = colors.default.blue,
        ["Shell"] = colors.default.red,
    }
    for mode, bg in pairs(modes) do
        vim.api.nvim_set_hl(0, "StatusMode" .. mode, { fg = "Black", bg = bg })
    end
    for _, hl in ipairs({"Error", "Warn", "Info", "Hint"}) do
        local dhl = vim.api.nvim_get_hl_by_name("DiagnosticSign" .. hl, true)
        vim.api.nvim_set_hl(0, "StatusDiagnostic" .. hl, { fg = dhl.foreground, bg = base.background })
    end
    local colors_ex = vim.o.background == "dark" and colors.dark or colors.light
    vim.api.nvim_set_hl(0, "StatusVcs", {fg = colors_ex.magenta, bg = base.background})
    vim.api.nvim_set_hl(0, "StatusDiffAdd", {fg = colors_ex.green, bg = base.background})
    vim.api.nvim_set_hl(0, "StatusDiffModify", {fg = colors_ex.orange, bg = base.background})
    vim.api.nvim_set_hl(0, "StatusDiffRemove", {fg = colors_ex.red, bg = base.background})
end


local statusline_left = {
    {
        fn = function(bufnr)
            local bt = vim.api.nvim_buf_get_option(bufnr, "buftype")
            if bt == "" then return vim.api.nvim_eval_statusline("%y", {}).str end
            return  "%y" .. "[" .. bt ..  "]"
        end
    },
    {
        fn = function(bufnr)
            local d = GETLOCAL(bufnr, "project", "root")
            if not d then return "" end
            return "PRJ: " .. replacehome(d)
        end
    },
    {
        fn = function(bufnr)
            local d = GETLOCAL(bufnr, "directory")
            if not d then return "" end
            return "DIR: " .. replacehome(d)
        end
    },
}

local statusline_right = {
    {
        fn = function(bufnr)
            local diags = vim.diagnostic.get(bufnr, nil)
            if not diags or #diags == 0 then
                return ""
            end
            local sev = vim.diagnostic.severity
            local icons = {
                { sev.E, " ", "StatusDiagnosticError" },
                { sev.W, " ", "StatusDiagnosticWarn" },
                { sev.I, " ", "StatusDiagnosticInfo" },
                { sev.N, " ", "StatusDiagnosticHint" },
            }
            local counts = {}
            for _, s in pairs(sev) do
                counts[s] = 0
            end
            for _, d in ipairs(diags) do
                counts[d.severity] = counts[d.severity] + 1
            end
            local parts = {}
            for _, ii in ipairs(icons) do
                local count = counts[ii[1]]
                if count > 0 then
                    parts[#parts + 1] = highlighted(ii[3], ii[2] .. tostring(count))
                end
            end
            return table.concat(parts, " ")
        end
    },
    {
        fn = function(bufnr)
            local client_names = {}
            for _, client in ipairs(vim.lsp.buf_get_clients(bufnr)) do
                client_names[#client_names+1] = string.format("%s(%d)", client.name, client.id)
            end
            if #client_names == 0 then
                return ""
            end
            return string.format("LSP: %s", table.concat(client_names, ", "))
        end
    },
    {
        fn = function(bufnr)
            local vcs = require "my.vcs"
            if not vcs["buffer-has-vcs"](bufnr) then
                return ""
            end
            return highlighted("StatusVcs", " " .. vcs["find-head"](bufnr))
        end
    },
    {
        fn = function(bufnr)
            local stats = vim.call("sy#repo#get_stats", bufnr)
            if stats[1] == -1 and stats[2] == -1 and stats[3] == -1 then
                return ""
            end
            return highlighted("StatusDiffAdd", " " .. tostring(stats[1]))
                .. highlighted("StatusDiffModify", "  " .. tostring(stats[2]))
                .. highlighted("StatusDiffRemove", "  " .. tostring(stats[3]))
        end
    }
}


local function __Tablabel(tabid)
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
    local bufnr = vim.api.nvim_get_current_buf()
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
    local sl = {}
    for i = 1, #statusline_left do
        local v = statusline_left[i].fn(bufnr)
        if v and v ~= "" then
            sl[#sl + 1] = v
        end
    end
    local sr = {}
    for i = 1, #statusline_right do
        local v = statusline_right[i].fn(bufnr)
        if v and v ~= "" then
            sr[#sr + 1] = v
        end
    end
    return "%#StatusLine#"
            .. current_mode()
            .. " "
            .. table.concat(sl, " | ")
            .. "%="
            .. table.concat(sr, " | ")
            .. "%="
            .. table.concat(tabs, "%#TabLineFill# ")
end


local gid = vim.api.nvim_create_augroup("statusline", { clear = true })
vim.api.nvim_create_autocmd("ModeChanged", { command = "redrawtabline", group = gid })
vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_highlights, group = gid })


vim.o.tabline = "%!v:lua.__Tabline()"
vim.o.statusline = "%t %m%r%=%-14.(%l,%c%V%) %P"

--- tabline.lua ends here
