-- Plugins initialization


local pkg = ...

pkg {
    name = "fennel",
    url = "https://github.com/bakpakin/Fennel",
    opt = true,
    rtp = "rtp",
    run = function()
        vim.schedule(_F("bootstrap.fennel.ensure_compiler", "setup", {force = true}))
    end,
}

pkg {
    name = "conjure",
    url = "https://github.com/Olical/conjure",
    ft  = {"fennel"},
    opt = true,
}

pkg {
    name = "lazydev.nvim",
    url = "https://github.com/folke/lazydev.nvim",
}

pkg {
    name = "which-key",
    url = "https://github.com/folke/which-key.nvim",
    config = function()
        local M = require("which-key.plugins.registers")
        M.registers = M.registers:gsub("[+*]", "")
        require("which-key").setup{}
    end,
}

pkg {
    name = "fennel.vim",
    url = "https://github.com/bakpakin/fennel.vim",
}

-- completion with nvim-cmp
pkg {
    name = "cmp",
    url = "https://github.com/hrsh7th/nvim-cmp",
    keys = { {"i", "<C-x><C-x>"}, },
    event = {"InsertEnter"},
    module = {"cmp"},
    opt = true,
    config = function() _T("my.pack.cmp", "setup") end,
}

pkg {
    name = "cmp-lsp",
    url = "https://github.com/hrsh7th/cmp-nvim-lsp",
    after = {"cmp"},
    opt = true,
    run = function(...) _T("my.pack.cmp-lsp", "reset", ...) end,
    config = function() _T("my.pack.cmp-lsp", "setup") end,
}

pkg {
    name ="cmp-buffer",
    after = {"cmp"},
    opt = true,
    url = "https://github.com/hrsh7th/cmp-buffer",
}

pkg {
    name = "cmp-path",
    after = {"cmp"},
    opt = true,
    url = "https://github.com/hrsh7th/cmp-path",
}
pkg {
    name = "cmp-nvim-lua",
    after = {"cmp"},
    opt = true,
    url = "https://github.com/hrsh7th/cmp-nvim-lua",
}

pkg {
    name = "cmp-conjure",
    url = "https://github.com/PaterJason/cmp-conjure",
    opt = true,
    after = {"conjure", "cmp"},
}

-- end
pkg {
    name = "colorizer",
    url = "https://github.com/catgoose/nvim-colorizer.lua",
    config = function() _T("colorizer", "setup") end,
}

pkg {
    name = "terminal",
    url = "https://github.com/norcalli/nvim-terminal.lua",
    ft = "terminal",
    config = function ()
        _T("terminal", "setup")
        local bufnr = tonumber(vim.fn.expand("<abuf>"))
        local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
        if ft == "terminal" then
            vim.api.nvim_buf_call(bufnr, function()
                vim.cmd "doautocmd <nomodeline> FileType terminal"
            end)
        end
    end,
}

pkg {
    name = "popup",
    url = "https://github.com/nvim-lua/popup.nvim",
}

pkg {
    name = "plenary",
    url = "https://github.com/nvim-lua/plenary.nvim",
}

pkg {
    name = "nui",
    url = "https://github.com/MunifTanjim/nui.nvim",
}

pkg {
    name = "parinfer-lua",
    url = "https://github.com/gpanders/nvim-parinfer",
}

pkg {
    name = "neorg",
    url = "https://github.com/nvim-neorg/neorg",
    opt = true,
    cmd = {"NeorgStart"},
    ft = "norg",
    config = function(name, pkginfo)
        _T("my.pack.neorg", "setup", name, pkginfo)
    end,
}

if false then
    pkg {
        name = "fzf",
        url = "https://github.com/junegunn/fzf",
        run = function() vim.call("fzf#install") end,
    }

    pkg {
        name = "fzf.vim",
        url = "https://github.com/junegunn/fzf.vim",
        config = function() _T("my.pack.fzf", "setup") end,
        requires = {"fzf"},
    }
end

pkg {
    name = "diffview",
    url = "https://github.com/sindrets/diffview.nvim",
    opt = true,
    cmd = (function()
        local cmds = {}
        local subcmd = {
            "Open", "Close", "Refresh", "Log",
            "FocusFiles", "ToggleFiles",
        }
        for i, v in ipairs(subcmd) do
            cmds[i] = "Diffview" .. v
        end
        return cmds
    end)(),
}

pkg {
    name = "readline.vim",
    url = "https://github.com/ryvnf/readline.vim",
    event = "CmdlineEnter",
}

pkg {
    name = "snippets.nvim",
    url = "https://github.com/norcalli/snippets.nvim",
    event = "InsertCharPre",
}

pkg {
    name = "rest-client",
    url = "https://github.com/NTBBloodbath/rest.nvim",
    disable = true,
}

-- LSP
pkg {
    name = "lspconfig",
    url = "https://github.com/neovim/nvim-lspconfig",
    config = function()
        package.preload.lspconfig = function(...)
            error("[LOAD PROHIBITED] " .. vim.inspect{...})
        end
    end,
}

pkg {
    name = "none-ls",
    url = "https://github.com/nvimtools/none-ls.nvim",
    opt = true,
    cmd = {"NullLsLog", "NullLsInfo"},
    module = {"null-ls"},
}

pkg {
    name = "lsptrouble",
    url = "https://github.com/folke/lsp-trouble.nvim",
    event = {"DiagnosticChanged"},
    cmd = {"Trouble", "TroubleToggle", "TroubleRefresh", "TroubleClose"},
    config = function() _T("my.pack.lsptrouble", "setup") end,
}

pkg {
    name = "mason",
    url = "https://github.com/williamboman/mason.nvim",
    config = function() _T("my.pack.mason", "setup") end
}

pkg {
    name = "lspkind",
    url = "https://github.com/onsails/lspkind-nvim",
}

-- Debugging
pkg {
    name = "nvim-dap",
    url = "https://github.com/mfussenegger/nvim-dap",
}

pkg {
    name = "nvim-gdb",
    url = "https://github.com/sakhnik/nvim-gdb",
}

-- Treesitter
pkg {
    name = "nvim-treesitter",
    url = "https://github.com/nvim-treesitter/nvim-treesitter",
    config = function() _T("my.treesitter", "setup") end,
}

pkg {
    name = "nvim-treesitter-textobjects",
    url = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
}

-- File-specific

pkg {
    name = "vim-fish",
    url = "https://github.com/dag/vim-fish",
}

pkg {
    name = "python-pep8-indent",
    url = "https://github.com/Vimjas/vim-python-pep8-indent",
    ft = {"python", "cython"},
}

-- Editing
-- pkg {
--     name = "langmapper",
--     url = "https://github.com/Wansmer/langmapper.nvim",
--     config = function()
--         require("langmapper").setup{}
--     end,
-- }

pkg {
    name = "table-mode",
    url = "https://github.com/dhruvasagar/vim-table-mode",
    cmd = {"Tableize", "TableModeEnable", "TableModeToggle"},
}

pkg {
    name = "tabular",
    url = "https://github.com/godlygeek/tabular",
    cmd = {"Tabularize"},
}

pkg {
    name = "easy-align",
    url = "https://github.com/junegunn/vim-easy-align",
    cmd = {"EasyAlign"},
}

pkg {
    name = "matchup",
    url = "https://github.com/andymass/vim-matchup",
    config = function()
        vim.g.matchup_matchparen_offscreen = {
            method = "popup"
        }
    end,
}

pkg {
    name = "nvim-surround",
    url = "https://github.com/kylechui/nvim-surround",
    config = function() _T("nvim-surround", "setup") end
}

pkg {
    name = "visual-multi",
    url = "https://github.com/mg979/vim-visual-multi",
}

pkg {
    name = "comment",
    url = "https://github.com/numToStr/Comment.nvim",
    config = function() _T("Comment", "setup") end,
}

pkg {
    name = "neogen",
    url = "https://github.com/danymat/neogen",
    opt = true,
    keys = {{"n", "<leader>nf"}},
    config = function() _T("my.pack.neogen", "setup") end,
}

pkg {
    name = "far.vim",
    url = "https://github.com/brooth/far.vim",
    cmd = {"Farr", "Farf"},
    config = function()
        vim.g["far#source"] = "rg"
    end
}

-- VCS
pkg {
    name = "signify",
    url = "https://github.com/mhinz/vim-signify",
}

pkg {
    name = "vim-fugitive",
    url = "https://github.com/tpope/vim-fugitive",
}

-- Repl
pkg {
    name = "iron.nvim",
    url = "https://github.com/hkupty/iron.nvim",
}

-- Telescope
pkg {
    name = "telescope",
    url = "https://github.com/nvim-telescope/telescope.nvim",
    opt = true,
    cmd = {"Telescope"},
    module = {"telescope"},
    setup = function() _T("my.pack.telescope-init", "setup") end,
    config = function() _T("my.pack.telescope", "setup") end,
}

pkg {
    name = "telescope-file-browser",
    url = "https://github.com/nvim-telescope/telescope-file-browser.nvim",
    opt = true,
    after = {"telescope"},
    keys = {{"n", "<C-x>f"}},
    config = function()
        _T("my.pack.telescope-file-browser", "setup")
    end
}

pkg {
    name = "telescope-fzf-native",
    url = "https://github.com/nvim-telescope/telescope-fzf-native.nvim",
    opt = true,
    after = { "telescope" },
    run = function(...) _T("my.pack.telescope-fzf-native", "compile-library", ...) end,
    config = function() _T("my.pack.telescope-fzf-native", "setup") end,
}

-- FileTree
pkg {
    name = "oil",
    url = "https://github.com/stevearc/oil.nvim",
    config = function()
        _T("my.pack.oil", "setup")
    end,
}

-- Tasks
pkg {
    name = "asyncrun",
    url = "https://github.com/skywind3000/asyncrun.vim",
    cmd = {"Make", "AsyncRun", "AsyncStop"},
    config = function() _T("my.pack.asyncrun", "setup") end,
}

pkg {
    name = "asynctasks",
    url = "https://github.com/skywind3000/asynctasks.vim",
    cmd = {"AsyncTask", "AsyncTaskList", "AsyncTaskMacro", "AsyncTaskProfile"},
    wants = {"asyncrun"},
}

-- UI
pkg {
    name = "devicons",
    url = "https://github.com/kyazdani42/nvim-web-devicons",
    config = function() _T("nvim-web-devicons", "setup") end,
}

pkg {
    name = "prettier-quickfix",
    url = "https://github.com/yorickpeterse/nvim-pqf",
    config = function() _T("pqf", "setup") end,
}

pkg {
    name = "better-quickfix",
    url = "https://github.com/kevinhwang91/nvim-bqf",
}

-- Theming libs
pkg {
    name = "colorbuddy",
    url = "https://github.com/tjdevries/colorbuddy.nvim",
}

pkg {
    name = "lush",
    url = "https://github.com/rktjmp/lush.nvim",
}

-- Themes
pkg {
    name = "darcula-solid-theme",
    url = "https://github.com/briones-gabriel/darcula-solid.nvim",
}

pkg {
    name = "edge-theme",
    url = "https://github.com/sainnhe/edge",
}

pkg {
    name = "kanagawa-theme",
    url = "https://github.com/rebelot/kanagawa.nvim",
}

pkg {
    name = "inspired-github-theme",
    url = "https://github.com/mvpopuk/inspired-github.vim",
}

pkg {
    name = "papercolor-theme",
    url = "https://github.com/NLKNguyen/papercolor-theme",
}

pkg {
    name = "modus-theme",
    url = "https://github.com/ishan9299/modus-theme-vim",
}

pkg {
    name = "happyhacking-theme",
    url = "https://github.com/yorickpeterse/happy_hacking.vim",
}

pkg {
    name = "grey-theme",
    url = "https://github.com/yorickpeterse/nvim-grey",
}

pkg {
    name = "paper-theme",
    url = "https://github.com/yorickpeterse/vim-paper",
}
