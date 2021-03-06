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
        opt = true,
        init = function()
            hook.after.filetype("fennel", function()
                local var = "conjure#client#fennel#aniseed#aniseed_module_prefix"
                vim.g[var] = "aniseed."
                require("bootstrap.fennel.compiler").initialize()
                pkg.add("conjure")
                if pkg.installed("compe") and pkg.installed("compe-conjure") then
                    pkg.add("compe-conjure")
                    require'compe'.register_source('conjure', require'compe_conjure')
                end
            end)
        end
    } 

    pkg.def {
        name = "compe-conjure",
        url = "tami5/compe-conjure",
        opt = true,
    }

    pkg.def {
        name = "colorizer",
        url = "norcalli/nvim-colorizer.lua",
        init = function()
            require("colorizer").setup()
        end
    }

    pkg.def {
        name = "profiler",
        url = "norcalli/profiler.nvim",
        opt = true,
    }

    pkg.def{ name = "popup", url = "nvim-lua/popup.nvim" }
    pkg.def{ name = "plenary", url = "nvim-lua/plenary.nvim" }

    pkg.def {
        name = "fix-cursor-hold",
        url = "antoinemadec/FixCursorHold.nvim",
        init = function()
            vim.g.cursorhold_updatetime = 1000
        end
    }

    if vim.fn.exepath("cargo") ~= "" then
        pkg.def {
            name = "parinfer-rust",
            url = "eraserhd/parinfer-rust",
            on_update = "cargo build --release"
        }
    end

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
            -- vim.api.nvim_set_keymap('n', '<C-x>b', ':Buffers<CR>', {})
        end
    }

    pkg.def { name = "fennel.vim", url = "bakpakin/fennel.vim" }
    pkg.def { name = "readline.vim", url = "ryvnf/readline.vim" }

    pkg.def { name = "which-key", url = "liuchengxu/vim-which-key" }

    pkg.def {
        name = "vim-fish",
        url = "dag/vim-fish"
    }

    pkg.def {
        name = "compe",
        url = "hrsh7th/nvim-compe",
        init = function ()
            require("compe").setup {
                enabled = true,
                source = {
                    path = true,
                    buffer = true,
                    calc = true,
                    nvim_lsp = true,
                    nvim_lua = true,
                    snippets_nvim = true,
                    treesitter = true,
                    conjure = true,
                }
            }
            function map(key, action) 
                local opt = { noremap = true, silent = true, expr = true}
                vim.api.nvim_set_keymap("i", key, action, opt)
            end
            map("<C-x><C-x>", "compe#complete()")
            map("<CR>", "compe#confirm('<CR>')")
            map("<C-q>", "compe#close('<C-q>')")
        end
    }

    pkg.def { name = "snippets.nvim", url = "norcalli/snippets.nvim" }

    pkg.def {
        name = "nvim-lspconfig",
        url = "neovim/nvim-lspconfig",
        init = function()
            package.loaded["nvim_lsp"] = require("lspconfig")
        end
    }

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
    -- vim.g.loaded_netrw = 1
    -- vim.g.loaded_netrwPlugin = 1

    require"bootstrap.trampouline".setup()
    require"bootstrap.loaded".setup()
    require"bootstrap.indent".setup()
    require"bootstrap.keybind".setup()
    require"bootstrap.terminal".setup()

    pkg.def {
	name = "aniseed",
	url = "Olical/aniseed",
	opt = true
    }

    pcall(pkg.add, "aniseed")
    if pcall(pkg.add, "profiler") then
        require "profiler"
        M.runlisp = WRAP(M.runlisp)
        M.finalize = WRAP(M.finalize)
    end
end

function M.runlisp()
    if pkg.installed("aniseed") then
        require("bootstrap.fennel").setup()
    end
end


function M.finalize()
    packages()
    plugin_commands()
    require"bootstrap.gui".setup()
    local ok, mod = pcall(function() return require"after" end)
    if ok and type(mod) == "table" and vim.is_callable(mod.setup) then
        mod.setup()
    end
end


return M

--- main.lua ends here
