-- Plugins initialization

local pkg = ...

pkg {
    name = "packer.nvim",
    url = "wbthomason/packer.nvim",
    opt = true,
}

pkg {
    name = "fennel",
    url = "bakpakin/Fennel",
    opt = true,
    rtp = "rtp",
    run = function()
        vim.schedule(_F("bootstrap.fennel.ensure_compiler", "setup", {force = true}))
    end,
}

pkg {
    name = "conjure",
    url = "Olical/conjure",
    ft  = {"fennel"},
    opt = true,
}

pkg {
    name = "neodev.nvim",
    url = "folke/neodev.nvim",
}

pkg {
    name = "which-key",
    url = "folke/which-key.nvim",
    config = function()
        local M = require("which-key.plugins.registers")
        M.registers = M.registers:gsub("[+*]", "")
        require("which-key").setup{}
    end,
}

pkg {
    name = "fennel.vim",
    url = "bakpakin/fennel.vim",
}

-- completion with nvim-cmp
pkg {
    name = "cmp",
    url = "hrsh7th/nvim-cmp",
    keys = { {"i", "<C-x><C-x>"}, },
    event = {"InsertEnter"},
    module = {"cmp"},
    opt = true,
    config = function() _T("my.pack.cmp", "setup") end,
}

pkg {
    name = "cmp-lsp",
    url = "hrsh7th/cmp-nvim-lsp",
    after = {"cmp"},
    opt = true,
    config = function() _T("my.pack.cmp-lsp", "setup") end,
}

pkg {
    name ="cmp-buffer",
    after = {"cmp"},
    opt = true,
    url = "hrsh7th/cmp-buffer",
}

pkg {
    name = "cmp-path",
    after = {"cmp"},
    opt = true,
    url = "hrsh7th/cmp-path",
}
pkg {
    name = "cmp-nvim-lua",
    after = {"cmp"},
    opt = true,
    url = "hrsh7th/cmp-nvim-lua",
}

pkg {
    name = "cmp-conjure",
    url = "PaterJason/cmp-conjure",
    opt = true,
    after = {"conjure", "cmp"},
}

pkg {
    name = "luasnip",
    url = "L3MON4D3/LuaSnip",
    after = {"cmp"},
    opt = true,
    config = function() _T("my.pack.luasnip", "setup") end,
}

pkg {
    name = "cmp-luasnip",
    url = "saadparwaiz1/cmp_luasnip",
    after = {"cmp"},
    opt = true,
}

-- end
pkg {
    name = "colorizer",
    url = "norcalli/nvim-colorizer.lua",
    config = function() _T("colorizer", "setup") end,
}

pkg {
    name = "terminal",
    url = "norcalli/nvim-terminal.lua",
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
    url = "nvim-lua/popup.nvim",
}

pkg {
    name = "plenary",
    url = "nvim-lua/plenary.nvim",
}

pkg {
    name = "nui",
    url = "MunifTanjim/nui.nvim",
}

pkg {
    name = "parinfer-lua",
    url = "gpanders/nvim-parinfer",
}

pkg {
    name = "neorg",
    url = "nvim-neorg/neorg",
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
        url = "junegunn/fzf",
        run = function() vim.call("fzf#install") end,
    }

    pkg {
        name = "fzf.vim",
        url = "junegunn/fzf.vim",
        config = function() _T("my.pack.fzf", "setup") end,
        requires = {"fzf"},
    }
end

pkg {
    name = "diffview",
    url = "sindrets/diffview.nvim",
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
    url = "ryvnf/readline.vim",
    event = "CmdlineEnter",
}

pkg {
    name = "snippets.nvim",
    url = "norcalli/snippets.nvim",
    event = "InsertCharPre",
}

pkg {
    name = "rest-client",
    url = "NTBBloodbath/rest.nvim",
}

-- LSP
pkg {
    name = "lspconfig",
    url = "neovim/nvim-lspconfig",
    module = {"lspconfig"},
    cmd = {"LspInfo", "LspStart", "LspStop", "LspRestart"},
    requires = {"cmp-lsp"},
    config = function() _T("my.pack.lspconfig", "setup") end,
    opt = true,
}

pkg {
    name = "none-ls",
    url = "nvimtools/none-ls.nvim",
    opt = true,
    cmd = {"NullLsLog", "NullLsInfo"},
    module = {"null-ls"},
}

pkg {
    name = "lsptrouble",
    url = "folke/lsp-trouble.nvim",
    event = {"DiagnosticChanged"},
    cmd = {"Trouble", "TroubleToggle", "TroubleRefresh", "TroubleClose"},
    config = function() _T("my.pack.lsptrouble", "setup") end,
}

pkg {
    name = "mason",
    url = "williamboman/mason.nvim",
    config = function() _T("my.pack.mason", "setup") end
}

pkg {
    name = "lspkind",
    url = "onsails/lspkind-nvim",
}

-- Debugging
pkg {
    name = "nvim-dap",
    url = "mfussenegger/nvim-dap",
}

pkg {
    name = "nvim-gdb",
    url = "sakhnik/nvim-gdb",
}

-- Treesitter
pkg {
    name = "nvim-treesitter",
    url = "nvim-treesitter/nvim-treesitter",
    config = function() _T("my.treesitter", "setup") end,
}

pkg {
    name = "nvim-treesitter-textobjects",
    url = "nvim-treesitter/nvim-treesitter-textobjects",
}

pkg {
    name = "nvim-treesitter-playground",
    url = "nvim-treesitter/playground",
}

-- File-specific

pkg {
    name = "vim-fish",
    url = "dag/vim-fish",
}

pkg {
    name = "python-pep8-indent",
    url = "Vimjas/vim-python-pep8-indent",
    ft = {"python", "cython"},
}

-- Editing
-- pkg {
--     name = "langmapper",
--     url = "Wansmer/langmapper.nvim",
--     config = function()
--         require("langmapper").setup{}
--     end,
-- }

pkg {
    name = "table-mode",
    url = "dhruvasagar/vim-table-mode",
    cmd = {"Tableize", "TableModeEnable", "TableModeToggle"},
}

pkg {
    name = "tabular",
    url = "godlygeek/tabular",
    cmd = {"Tabularize"},
}

pkg {
    name = "easy-align",
    url = "junegunn/vim-easy-align",
    cmd = {"EasyAlign"},
}

pkg {
    name = "matchup",
    url = "andymass/vim-matchup",
    config = function()
        vim.g.matchup_matchparen_offscreen = {
            method = "popup"
        }
    end,
}

pkg {
    name = "nvim-surround",
    url = "kylechui/nvim-surround",
    config = function() _T("nvim-surround", "setup") end
}

pkg {
    name = "visual-multi",
    url = "mg979/vim-visual-multi",
}

pkg {
    name = "comment",
    url = "numToStr/Comment.nvim",
    config = function() _T("Comment", "setup") end,
}

pkg {
    name = "neogen",
    url = "danymat/neogen",
    opt = true,
    keys = {{"n", "<leader>nf"}},
    config = function() _T("my.pack.neogen", "setup") end,
}

pkg {
    name = "far.vim",
    url = "brooth/far.vim",
    cmd = {"Farr", "Farf"},
    config = function()
        vim.g["far#source"] = "rg"
    end
}

-- VCS
pkg {
    name = "signify",
    url = "mhinz/vim-signify",
}

pkg {
    name = "vim-fugitive",
    url = "tpope/vim-fugitive",
}

-- Repl
pkg {
    name = "iron.nvim",
    url = "hkupty/iron.nvim",
}

-- Telescope
pkg {
    name = "telescope",
    url = "nvim-telescope/telescope.nvim",
    opt = true,
    cmd = {"Telescope"},
    module = {"telescope"},
    setup = function() _T("my.pack.telescope-init", "setup") end,
    config = function() _T("my.pack.telescope", "setup") end,
}

pkg {
    name = "telescope-file-browser",
    url = "nvim-telescope/telescope-file-browser.nvim",
    opt = true,
    after = {"telescope"},
    keys = {{"n", "<C-x>f"}},
    config = function()
        _T("my.pack.telescope-file-browser", "setup")
    end
}

pkg {
    name = "telescope-fzf-native",
    url = "nvim-telescope/telescope-fzf-native.nvim",
    opt = true,
    after = { "telescope" },
    run = function(...) _T("my.pack.telescope-fzf-native", "compile-library", ...) end,
    config = function() _T("my.pack.telescope-fzf-native", "setup") end,
}

-- FileTree
pkg {
    name = "oil",
    url = "stevearc/oil.nvim",
    config = function()
        _T("my.pack.oil", "setup")
    end,
}

-- Tasks
pkg {
    name = "asyncrun",
    url = "skywind3000/asyncrun.vim",
    cmd = {"Make", "AsyncRun", "AsyncStop"},
    config = function() _T("my.pack.asyncrun", "setup") end,
}

pkg {
    name = "asynctasks",
    url = "skywind3000/asynctasks.vim",
    cmd = {"AsyncTask", "AsyncTaskList", "AsyncTaskMacro", "AsyncTaskProfile"},
    wants = {"asyncrun"},
}

-- UI
pkg {
    name = "devicons",
    url = "kyazdani42/nvim-web-devicons",
    config = function() _T("nvim-web-devicons", "setup") end,
}

pkg {
    name = "prettier-quickfix",
    url = "https://gitlab.com/yorickpeterse/nvim-pqf",
    config = function() _T("pqf", "setup") end,
}

pkg {
    name = "better-quickfix",
    url = "kevinhwang91/nvim-bqf",
}

-- Theming libs
pkg {
    name = "colorbuddy",
    url = "tjdevries/colorbuddy.nvim",
}

pkg {
    name = "lush",
    url = "rktjmp/lush.nvim",
}

-- Themes
pkg {
    name = "darcula-solid-theme",
    url = "briones-gabriel/darcula-solid.nvim",
}

pkg {
    name = "edge-theme",
    url = "sainnhe/edge",
}

pkg {
    name = "kanagawa-theme",
    url = "rebelot/kanagawa.nvim",
}

pkg {
    name = "inspired-github-theme",
    url = "mvpopuk/inspired-github.vim",
}

pkg {
    name = "papercolor-theme",
    url = "NLKNguyen/papercolor-theme",
}

pkg {
    name = "modus-theme",
    url = "ishan9299/modus-theme-vim",
}

pkg {
    name = "happyhacking-theme",
    url = "https://gitlab.com/yorickpeterse/happy_hacking.vim",
}

pkg {
    name = "grey-theme",
    url = "https://gitlab.com/yorickpeterse/nvim-grey",
}

pkg {
    name = "paper-theme",
    url = "https://gitlab.com/yorickpeterse/vim-paper",
}
