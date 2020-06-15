--- Main nvim entry point
--

require "bootstrap.loaded"
local hook = require "bootstrap.hook"
require "bootstrap.trampouline"
require "bootstrap.terminal"

local minpac = require "bootstrap.minpac"
local interop = require "bootstrap.interop"
local options = require "bootstrap.options"
local indent = require "bootstrap.indent"
local keybind = require "bootstrap.keybind"
local pkg = require "bootstrap.pkgmanager"


local M = {}

local function fennel_files(root)
    local result = {}
    local srcdir = root .. "/fnl"
    local dstdir = root .. "/lua"
    local prefixlen = srcdir:len()
    local sources = vim.fn.globpath(srcdir, "**/*.fnl", true, true)
    local getftime = vim.fn.getftime
    for _, srcpath in ipairs(sources) do
        local srcpath = srcpath:gsub("\\", "/")
        local suffix = srcpath:sub(prefixlen + 1)
        local dstpath = dstdir .. suffix:sub(1, -4) .. "lua"
        if getftime(srcpath) > getftime(dstpath) then
            result[srcpath] = dstpath
        end
    end
    return result
end


local function fennel_compile()
    local sources = fennel_files(vim.fn.stdpath('config'):gsub('\\', '/')) 

    if vim.tbl_isempty(sources) then
        return
    end

    local fennel = require"bootstrap.fennel"
    fennel.compiler_init()

    for src, dst in pairs(sources) do
        fennel.compile_file(src, dst, {}, true)
    end
end


local function fennel_init()
    require"my".setup()

    local def = interop.command{
        name = "EvalExpr",
        nargs = 1,
        modname = "bootstrap.fennel",
        funcname = "eval_print"
    }
    vim.api.nvim_command(def)

    def = interop.command{
        name = "InitRecompile",
        nargs = "*",
        modname = "bootstrap.fennel",
        funcname = "recompile"
    }
    vim.api.nvim_command(def)
end


local function lightline_init()
    if minpac.installed("vim-dogrun") then
        vim.g.lightline = { colorscheme = "dogrun" }
    else
        vim.g.lightline = { colorscheme = "one" }
    end
end


local function packages()
    pkg.def {
        name = "conjure",
        url = "Olical/conjure",
        kind = "opt",
        init = function()
            hook.after.filetype("fennel", function()
                pkg.add("conjure")
            end)
        end
    }

    pkg.def {
        name = "vim-vinegar",
        url = "tpope/vim-vinegar" 
    }

    pkg.def {
        name = "vim-fugitive",
        url = "tpope/vim-fugitive",
        kind = "start"
    }

    pkg.def {
        name = "vim-rooter",
        url = "airblade/vim-rooter",
        init = function()
            vim.schedule(function()
                vim.g['rooter_use_lcd'] = 1
                vim.g['rooter_change_directory_for_non_project_files'] = "current"
            end)
        end
    }

    pkg.def {
	name = "nvim-luadev",
	url = "bfredl/nvim-luadev",
        init = function() pkg.add("nvim-luadev") end,
	kind = "opt"
    }

    pkg.def {
        name = "vim-dogrun",
	url = "wadackel/vim-dogrun",
        init = function() vim.api.nvim_command("colorscheme dogrun") end
    }

    pkg.def {
        name = "bufferize.vim",
	url = "AndrewRadev/bufferize.vim",
        kind = "opt"
    }

    pkg.def {
	name = "lightline.vim",
	url = "itchyny/lightline.vim",
	init = function()
            if minpac.installed("vim-dogrun") then
	        vim.g.lightline = { colorscheme = "dogrun" }
	    end
	end
    }

    pkg.def {
        name = "parinfer-rust",
        url = "eraserhd/parinfer-rust",
        on_update = function()
            vim.cmd("!cargo build --release")
        end
    }

    pkg.def {
        name = "fzf",
        url = "junegunn/fzf",
        on_update = function()
            vim.cmd("packadd fzf")
            vim.fn["fzf#install"]()
        end
    }

    pkg.def {
        name = "fzf.vim",
        url = "junegunn/fzf.vim",
        init = function ()
            vim.api.nvim_set_keymap('n', '<C-x>f', ':Files<CR>', {})
            vim.api.nvim_set_keymap('n', '<C-x>b', ':Buffers<CR>', {})
        end
    }

    pkg.def { name = "fennel.vim", url = "bakpakin/fennel.vim" } 
    pkg.def { name = "impromptu.nvim", url = "Vigemus/impromptu.nvim" }
    pkg.def { name = "lightline.vim", url = "itchyny/lightline.vim" }
    pkg.def { name = "readline.vim", url = "ryvnf/readline.vim" }

    pkg.def { name = "which-key", url = "liuchengxu/vim-which-key" }

    pkg.def {
        name = "vim-clap",
        url = "liuchengxu/vim-clap",
        kind = "opt",
        init = function()
            hook.after.command("Clap", function()
                pkg.add("vim-clap")
                _trampouline("my.pack.clap", "setup")
            end)
        end
    }

    pkg.def {
        name = "completion-nvim",
        url = "haorenW1025/completion-nvim" ,
        kind = "opt",
        init = function()
            hook.after.bufenter(".*", function()
                pkg.add("completion-nvim")
                vim.api.nvim_set_keymap(
                    'i', '<C-TAB>', 'completion#trigger_completion()',
                    { noremap = true, silent = true, expr = true }
                )
            end)
        end
    }

    pkg.def {
        name = "diagnostic-nvim",
        url = "haorenW1025/diagnostic-nvim" ,
        kind = "opt",
        init = function()
            hook.after.bufenter(".*", function()
                pkg.add("diagnostic-nvim")
                vim.g["diagnostic_insert_delay"] = 1
            end)
        end
    }

    pkg.def { name = "nvim-lsp", url = "neovim/nvim-lsp" }
    pkg.def { name = "vista", url = "liuchengxu/vista.vim" }
end


local function plugin_commands()
    local update = interop.command {
        name = "PluginUpdate",
        modname = "bootstrap.main",
        funcname = "plugin_update",
    }
    vim.api.nvim_command(update)

    local install = interop.command {
        name = "PluginInstall",
        modname = "bootstrap.main",
        funcname = "plugin_install",
    }
    vim.api.nvim_command(install)

    local status = interop.command {
        name = "PluginStatus",
        modname = "bootstrap.main",
        funcname = "plugin_status"
    }
    vim.api.nvim_command(status)

    local plist = interop.command {
        name = "PluginList",
        modname = "bootstrap.main",
        funcname = "plugin_list"
    }
    vim.api.nvim_command(plist)

    local reload = interop.command {
        name = "InitReload",
        modname = "bootstrap.reload",
        funcname = "reload",
        nargs = "*"
    }
    vim.api.nvim_command(reload)
end


function M.plugin_update()
    return minpac.updateall()
end


function M.plugin_install()
    return minpac.install()
end


function M.plugin_status()
    return minpac.status()
end


function M.plugin_list()
    print(vim.inspect(minpac.getpluglist()))
end


function M.setup()
    minpac.download()
    options.setup()
    indent.setup()
    keybind.setup()

    pkg.def {
	name = "aniseed",
	url = "Olical/aniseed",
	kind = "opt"
    }

    if not pcall(pkg.add, "aniseed") then
        minpac.install()
        pkg.add("aniseed")
    end
end

function M.runlisp()
    fennel_compile()
    fennel_init()
end


function M.finalize()
    packages()
    plugin_commands()
    hook.on.source("netrw", function() vim.g.netrw_keepdir = 0 end)
    require"bootstrap.gui".setup()
end


return M 

--- main.lua ends here
