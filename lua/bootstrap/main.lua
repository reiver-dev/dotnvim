--- Main nvim entry point
--

local interop = require"bootstrap.interop"
local hook = require "bootstrap.hook"
local pkg = require "bootstrap.pkgmanager"

local M = {}


local function packages()
    pkg.def {
        name = "conjure",
        url = "Olical/conjure",
        kind = "opt",
        init = function()
            hook.after.filetype("fennel", function()
                require("bootstrap.fennel.compiler").initialize()
                local var = "conjure#client#fennel#aniseed#aniseed_module_prefix"
                vim.g[var] = "aniseed."
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
        name = "rooter",
        url = "airblade/vim-rooter",
        init = function()
            vim.schedule(function()
                vim.g.rooter_use_lcd = 1
                vim.g.rooter_change_directory_for_non_project_files = "current"
            end)
        end
    }

    pkg.def {
        name = "nord-theme",
        url = "arcticicestudio/nord-vim",
        init = function() vim.api.nvim_command("colorscheme nord") end
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
            if pkg.installed("nord-theme") then
	        vim.g.lightline = { colorscheme = "nord" }
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
        modname = "bootstrap.pkgmanager",
        funcname = "plugin_update",
        bang = true
    }
    vim.api.nvim_command(update)

    local install = interop.command {
        name = "PluginInstall",
        modname = "bootstrap.pkgmanager",
        funcname = "plugin_install",
    }
    vim.api.nvim_command(install)

    local status = interop.command {
        name = "PluginStatus",
        modname = "bootstrap.pkgmanager",
        funcname = "plugin_status"
    }
    vim.api.nvim_command(status)

    local plist = interop.command {
        name = "PluginClean",
        modname = "bootstrap.pkgmanager",
        funcname = "plugin_clean"
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


function M.setup()
    require"bootstrap.trampouline".setup()
    require"bootstrap.loaded".setup()
    require"bootstrap.options".setup()
    require"bootstrap.indent".setup()
    require"bootstrap.keybind".setup()
    require"bootstrap.terminal".setup()

    pkg.def {
	name = "aniseed",
	url = "Olical/aniseed",
	kind = "opt"
    }

    pcall(pkg.add, "aniseed")
end

function M.runlisp()
    if pkg.installed("aniseed") then
        local fennel = require"bootstrap.fennel"
        fennel.compile()
        fennel.init()
    end
end


function M.finalize()
    packages()
    plugin_commands()
    hook.on.source("netrw", function() vim.g.netrw_keepdir = 0 end)
    require"bootstrap.gui".setup()
end


return M 

--- main.lua ends here
