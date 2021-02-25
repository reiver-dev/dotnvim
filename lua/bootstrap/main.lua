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
                require("bootstrap.fennel.compiler").initialize()
                local var = "conjure#client#fennel#aniseed#aniseed_module_prefix"
                vim.g[var] = "aniseed."
                pkg.add("conjure")
            end)
        end
    }

    pkg.def {
        name = "colorbuddy.nvim",
        url = "tjdevries/colorbuddy.vim",
        opt = true
    }

    pkg.def {
        name = "colorizer",
        url = "norcalli/nvim-colorizer.lua"
    }

    pkg.def {
        name = "profiler",
        url = "norcalli/profiler.nvim"
    }

    pkg.def{ name = "popup", url = "nvim-lua/popup.nvim" }
    pkg.def{ name = "plenary", url = "nvim-lua/plenary.nvim" }
    pkg.def{ name = "telescope", url = "nvim-lua/telescope.nvim" }

    pkg.def {
        name = "fix-cursor-hold",
        url = "antoinemadec/FixCursorHold.nvim",
        init = function()
            vim.g.cursorhold_updatetime = 1000
        end
    }

    pkg.def {
        name = "onebuddy-theme",
        url = "Th3Whit3Wolf/onebuddy",
        opt = true,
        init = function()
            vim.cmd "packadd colorbuddy.nvim"
            vim.cmd "packadd onebuddy-theme"
            require('colorbuddy').colorscheme('onebuddy')
        end
    }

    pkg.def {
        name = "vim-vinegar",
        url = "tpope/vim-vinegar"
    }

    pkg.def {
	name = "lightline.vim",
	url = "itchyny/lightline.vim",
        init = function()
            vim.g.lightline = {
                active = {
                    left = {{'mode', 'paste'},
                            {'readonly', 'filename', 'modified'},
                            {'directory'}},
                    right = {{'lineinfo'},
                             {'percent'},
                             {'project', 'fileformat', 'fileencoding', 'filetype'}}
                },
                component = {
                    directory = "%<D:%(%<%{fnamemodify(getbufvar('', 'default_directory', ''), ':~')}%)",
                    project = "%<P:%(%<%{fnamemodify(getbufvar('', 'projectile', ''), ':~')}%)",
                }
            }
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
        opt = true,
        init = function()
            hook.after.command("Clap", function()
                pkg.add("vim-clap")
                _trampouline("my.pack.clap", "setup")
            end)
        end
    }

    pkg.def {
        name = "vim-fish",
        url = "dag/vim-fish"
    }

    -- pkg.def {
    --     name = "completion-nvim",
    --     url = "haorenW1025/completion-nvim" ,
    --     init = function()
    --         vim.lsp.handlers = vim.lsp.callbacks
    --         vim.g.completion_enable_snippet = "vim-vsnip"
    --         vim.g.completion_enable_auto_popup = 0
    --         vim.g.completion_chain_complete_list = {
    --             default = {
    --                 comment = {},
    --                 default = {
    --                     { complete_items = {"lsp", "snippet", "ts"} },
    --                     { mode = "<c-p>" },
    --                     { mode = "<c-n>" }
    --                 }
    --             }
    --         }
    --         hook.on.bufenter(".*", function()
    --             if vim.bo.buftype == "" then
    --                 require'completion'.on_attach()
    --                 vim.api.nvim_buf_set_keymap(0, 'i',
    --                     '<C-x><C-x>', 'completion#trigger_completion()',
    --                     { noremap = true, silent = true, expr = true }
    --                 )
    --             end
    --         end)
    --     end
    -- }

    pkg.def {
        name = "nvim-compe",
        url = "hrsh7th/nvim-compe",
        init = function ()
            require("compe").setup {
                enabled = true,
                source = {
                    path = true,
                    buffer = true,
                    calc = true,
                    nvim_lsp = true
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

    pkg.def { name = "vim-vsnip", url =  "hrsh7th/vim-vsnip" }
    -- pkg.def { name = "vim-vsnip-integ", url = "hrsh7th/vim-vsnip-integ" }

    pkg.def {
        name = "nvim-lspconfig",
        url = "neovim/nvim-lspconfig",
        init = function()
            package.loaded["nvim_lsp"] = require("lspconfig")
        end
    }

    pkg.def { name = "vista", url = "liuchengxu/vista.vim" }

    pkg.def { name = "nvim-treesitter", url = "nvim-treesitter/nvim-treesitter" }
    pkg.def { name = "nvim-treesitter-playground", url = "nvim-treesitter/playground" }
    -- pkg.def { name = "nvim-treesitter-completion", url = "nvim-treesitter/completion-treesitter" }
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
