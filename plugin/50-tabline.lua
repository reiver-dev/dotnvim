--- Configure tabline


local sep = package.config:sub(1, 1) == "\\" and "[\\/]+" or "/+"
local HOME = "^" .. string.gsub(vim.pesc(vim.env.HOME), sep, sep)
local fmt, gsub = string.format, string.gsub
local api = vim.api


local function replacehome(path)
    return gsub(path, HOME, "~")
end


local function highlighted(hl, body)
    return fmt("%%#%s#%s%%#StatusLine#", hl, body)
end


local function highlighted_prefix(hl, body)
    return fmt("%%#%s#%s", hl, body)
end

--- @alias Color integer|string
--- @alias HL {fg: Color, bg: Color}

--- @param name string Highlight name
--- @return HL
local function get_hl(name)
    return api.nvim_get_hl(0, { name = name })
end


--- @param name string Highlight name
--- @param hl HL Definition
local function set_hl(name, hl)
    api.nvim_set_hl(0, name, hl)
end


local function current_mode()
    local m = require "statusline.mode"
    local mode = api.nvim_get_mode().mode
    local s = m.mode_to_symbol[mode]
    return highlighted("StatusMode" .. s[1], " " .. s[2] .. " ")
end


local function setup_highlights()
    local base = get_hl("StatusLine")
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
        set_hl("StatusMode" .. mode, { fg = "Black", bg = bg })
    end
    for _, hl in ipairs({ "Error", "Warn", "Info", "Hint" }) do
        local dhl = get_hl("DiagnosticSign" .. hl)
        set_hl("StatusDiagnostic" .. hl, { fg = dhl.fg, bg = base.bg })
    end
    local colors_ex = vim.o.background == "dark" and colors.dark or colors.light
    set_hl("StatusVcs", { fg = colors_ex.magenta, bg = base.bg })
    set_hl("StatusDiffAdd", { fg = colors_ex.green, bg = base.bg })
    set_hl("StatusDiffModify", { fg = colors_ex.orange, bg = base.bg })
    set_hl("StatusDiffRemove", { fg = colors_ex.red, bg = base.bg })
end


local statusline_left = {
    {
        fn = function(bufnr)
            local bt = api.nvim_buf_get_option(bufnr, "buftype")
            if bt == "" then
                return api.nvim_eval_statusline("%y", {}).str
            end
            return "%y" .. "[" .. bt .. "]"
        end
    },
    {
        fn = function(bufnr)
            local d = GETLOCAL(bufnr, "project", "root")
            if not d then
                return ""
            end
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
                    parts[#parts + 1] = highlighted_prefix(ii[3], ii[2] .. fmt("%-2d", count))
                end
            end
            if #parts then
                parts[#parts] = parts[#parts] .. "%#StatusLine#"
                return table.concat(parts, " ")
            else
                return ""
            end
        end
    },
    {
        fn = function(bufnr)
            local client_names = {}
            for _, client in pairs(vim.lsp.get_active_clients({ bufnr = bufnr })) do
                client_names[#client_names + 1] = fmt("%s(%d)", client.name, client.id)
            end
            if #client_names == 0 then
                return ""
            end
            table.sort(client_names)
            return fmt("LSP: %s", table.concat(client_names, ", "))
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
            local ok, stats = pcall(vim.call, "sy#repo#get_stats", bufnr)
            if not ok or stats == nil then
                return ""
            end
            if stats[1] == -1 and stats[2] == -1 and stats[3] == -1 then
                return ""
            end
            return highlighted_prefix("StatusDiffAdd", " " .. fmt("%-2d", stats[1]))
                .. highlighted_prefix("StatusDiffModify", "  " .. fmt("%-2d", stats[2]))
                .. highlighted("StatusDiffRemove", "  " .. fmt("%-2d", stats[3]))
        end
    }
}


local function tablabel(tabid)
    local windows = api.nvim_tabpage_list_wins(tabid)
    local window_count = 0
    local diff_count = 0
    for _, winid in ipairs(windows) do
        -- do not count floating widnows
        local wincfg = api.nvim_win_get_config(winid)
        if wincfg.relative == "" then
            window_count = window_count + 1
        end
        -- keep track of diff buffers
        if api.nvim_win_get_option(winid, "diff") then
            diff_count = diff_count + 1
        end
    end
    local components = { fmt("#%d/%d", tabid, window_count) }
    if diff_count > 0 then
        components[#components + 1] = fmt("D(%d)", diff_count)
    end
    return table.concat(components, " ")
end


local function tabsegment()
    local tabpages = api.nvim_list_tabpages()
    local current_tabpage = api.nvim_get_current_tabpage()
    local tabs = {}
    for i, tabpagenum in ipairs(tabpages) do
        local hl
        if tabpagenum == current_tabpage then
            hl = "%#TablineSel#"
        else
            hl = "%#TabLine#"
        end
        local label = fmt(" %%%dT%s%%T ", i, tablabel(tabpagenum))
        tabs[i] = fmt("%s%s", hl, label)
    end
    return tabs
end


function __Tabline()
    local bufnr = api.nvim_get_current_buf()
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
    local tabs = tabsegment()
    return current_mode()
        .. " "
        .. table.concat(sl, " | ")
        .. "%="
        .. table.concat(sr, " | ")
        .. fmt("%%%d(", #tabs * 10)
        .. table.concat(tabs, "")
        .. "%)"
end

local gid = api.nvim_create_augroup("statusline", { clear = true })
api.nvim_create_autocmd("ModeChanged", { command = "redrawtabline", group = gid })
api.nvim_create_autocmd("ColorScheme", { callback = setup_highlights, group = gid })


vim.o.tabline = "%!v:lua.__Tabline()"
vim.o.statusline = "W:%-4{winnr()} B:%-4n %t %m%r%=%-14.(%l,%c%V%)  %P"

--- tabline.lua ends here
