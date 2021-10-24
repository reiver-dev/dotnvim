;;; Main package configuration


(fn configure-packages [{: pkg}]
  (pkg :name :packer.nvim
       :url "wbthomason/packer.nvim"
       :opt true)

  (pkg :name :fennel
       :url "bakpakin/Fennel"
       :opt true
       :run #(vim.schedule
               #(_T :bootstrap.fennel.ensure_compiler :setup {:force true})))

  (pkg :name :conjure
       :url "Olical/conjure"
       :ft ["fennel"]
       :opt true)

  ;; completion with nvim-cmp
  (pkg :name "cmp"
       :url "hrsh7th/nvim-cmp"
       :event ["InsertEnter"]
       :opt true
       :config #(_T :my.pack.cmp :setup))

  (pkg :name "cmp-lsp"
       :url "hrsh7th/cmp-nvim-lsp"
       :after ["cmp"]
       :opt true
       :config #(_T :my.pack.cmp-lsp :setup))

  (pkg :name "cmp-buffer"
       :after ["cmp"]
       :opt true
       :url "hrsh7th/cmp-buffer")

  (pkg :name "cmp-path"
       :after ["cmp"]
       :opt true
       :url "hrsh7th/cmp-path")

  (pkg :name "cmp-nvim-lua"
       :after ["cmp"]
       :opt true
       :url "hrsh7th/cmp-nvim-lua")

  (pkg :name "cmp-conjure"
       :url "PaterJason/cmp-conjure"
       :opt true
       :after ["conjure" "cmp"])

  ;; end

  (pkg :name "fix-cursor-hold"
       :url "antoinemadec/FixCursorHold.nvim"
       :config #(set vim.g.cursorhold_updatetime 1000))

  (pkg :name :colorizer
       :url "norcalli/nvim-colorizer.lua"
       :config #(_T :colorizer :setup))

  (pkg :name :terminal
       :url "norcalli/nvim-terminal.lua"
       :ft "terminal"
       :config (fn []
                 (_T :terminal :setup)
                 (let [bufnr (tonumber (vim.fn.expand "<abuf>"))
                       ft (vim.api.nvim_buf_get_option bufnr :filetype)]
                   (when (= ft "terminal")
                     (vim.api.nvim_buf_call
                       bufnr #(vim.cmd "doautocmd <nomodeline> FileType terminal"))))))


  (pkg :name :profiler
       :url "norcalli/profiler.nvim"
       :opt true
       :module "profiler")

  (pkg :name :popup
       :url "nvim-lua/popup.nvim")

  (pkg :name :plenary
       :url "nvim-lua/plenary.nvim")

  (pkg :name :parinfer
       :url "eraserhd/parinfer-rust"
       :ft (_T :my.pack.parinfer :filetypes)
       :run #(_T :my.pack.parinfer :compile-library)
       :config #(_T :my.pack.parinfer :setup))


  (pkg :name :fzf
       :url "junegunn/fzf"
       :run (fn [] (vim.call "fzf#install")))

  (pkg :name :fzf.vim
       :url "junegunn/fzf.vim"
       :config (fn [] (_T :my.pack.fzf :setup))
       :requires ["fzf"])

  (pkg :name :diffview
       :url "sindrets/diffview.nvim")

  (pkg :name :which-key
       :url "folke/which-key.nvim"
       :config #(_T :which-key :setup {}))

  (pkg :name "readline.vim"
       :url "ryvnf/readline.vim"
       :event "CmdlineEnter")

  (pkg :name "snippets.nvim"
       :url "norcalli/snippets.nvim"
       :event "InsertCharPre")

  (pkg :name "rest-client"
       :url "NTBBloodbath/rest.nvim")

  ;; LSP
  (pkg :name :lspconfig
       :url "neovim/nvim-lspconfig"
       :module ["lspconfig"]
       :cmd [:LspInfo :LspStart :LspStop :LspRestart]
       :opt true)

  (pkg :name :lsptrouble
       :url "folke/lsp-trouble.nvim"
       :config #(_T :my.pack.lsptrouble :setup))

  (pkg :name :lspcolors
       :url "folke/lsp-colors.nvim")

  (pkg :name :vista
       :url "liuchengxu/vista.vim"
       :cmd ["Vista"])

  (pkg :name "lspkind"
       :url "onsails/lspkind-nvim")

  ;; Debugging
  (pkg :name "fennel.vim"
       :url "bakpakin/fennel.vim")

  (pkg :name :nvim-dap
       :url "mfussenegger/nvim-dap")

  (pkg :name :nvim-gdb
       :url "sakhnik/nvim-gdb")

  ;; Treesitter
  (pkg :name "nvim-treesitter"
       :url "nvim-treesitter/nvim-treesitter"
       :config #(_T :my.treesitter :setup))

  (pkg :name "nvim-treesitter-playground"
       :url "nvim-treesitter/playground")

  ;; File-specific

  (pkg :name "vim-fish"
       :url "dag/vim-fish")

  (pkg :name "python-pep8-indent"
       :url "Vimjas/vim-python-pep8-indent"
       :ft ["python" "cython"])

  ;; Editing
  (pkg :name :table-mode
       :url "dhruvasagar/vim-table-mode"
       :cmd ["Tableize" "TableModeEnable" "TableModeToggle"])

  (pkg :name :tabular
       :url "godlygeek/tabular"
       :cmd ["Tabularize"])

  (pkg :name :easy-align
       :url "junegunn/vim-easy-align"
       :cmd ["EasyAlign"])

  (pkg :name "matchup"
       :url "andymass/vim-matchup"
       :config (fn []
                 (set vim.g.matchup_matchparen_offscreen {:method :popup})))

  (pkg :name :surround
       :url "tpope/vim-surround")

  (pkg :name :visual-multi
       :url "mg979/vim-visual-multi")

  (pkg :name "comment"
       :url "numToStr/Comment.nvim"
       :config #(_T "Comment" :setup))

  (pkg :name "far.vim"
       :url "brooth/far.vim"
       :cmd ["Farr" "Farf"]
       :config #(tset vim.g "far#source" "rg"))

  ;; VCS
  (pkg :name :signify
       :url "mhinz/vim-signify")

  (pkg :name "vim-fugitive"
       :url "tpope/vim-fugitive")

  ;; Repl
  (pkg :name "iron.nvim"
       :url "hkupty/iron.nvim")

  ;; Telescope
  (pkg :name "telescope"
       :url "nvim-telescope/telescope.nvim"
       :config #(_T :my.pack.telescope :setup))

  (pkg :name "telescope-fzy-native"
       :url "nvim-telescope/telescope-fzy-native.nvim"
       :config #(_T :my.pack.telescope-fzy-native :setup))

  ;; FileTree
  (pkg :name "vinegar"
       :url "tpope/vim-vinegar")

  (pkg :name "tree"
       :url "kyazdani42/nvim-tree.lua"
       :cmd [:NvimTreeOpen :NvimTreeToggle]
       :config #(_T :my.pack.tree :setup))

  ;; Tasks
  (pkg :name :asyncrun
       :url "skywind3000/asyncrun.vim"
       :cmd ["Make" "AsyncRun" "AsyncStop"]
       :config #(_T :my.pack.asyncrun :setup))

  (pkg :name :asynctasks
       :url "skywind3000/asynctasks.vim"
       :cmd ["AsyncTask" "AsyncTaskList" "AsyncTaskMacro" "AsyncTaskProfile"]
       :wants ["asyncrun"])

  ;; UI
  (pkg :name :devicons
       :url "kyazdani42/nvim-web-devicons"
       :config #(_T :nvim-web-devicons :setup))

  (pkg :name :galaxyline
       :url "NTBBloodbath/galaxyline.nvim"
       :branch "main"
       :requires [:devicons]
       :config #(require "my.ui.galaxyline"))

  (pkg :name :better-whitespace
       :url "ntpeters/vim-better-whitespace"
       :config #(set vim.g.better_whitespace_filetypes_blacklist
                     (vim.tbl_flatten
                       [["packer"]
                        vim.g.better_whitespace_filetypes_blacklist])))

  (pkg :name "prettier-quickfix"
       :url "https://gitlab.com/yorickpeterse/nvim-pqf"
       :config #(_T :pqf :setup))

  (pkg :name "better-quickfix"
       :url "kevinhwang91/nvim-bqf")

  ;; Theming libs
  (pkg :name "colorbuddy"
       :url "tjdevries/colorbuddy.nvim")

  (pkg :name "lush"
       :url "rktjmp/lush.nvim")

  ;; Themes
  (pkg :name "jellybeans-theme"
       :url "metalelf0/jellybeans-nvim")

  (pkg :name "onedark-theme"
       :url "olimorris/onedark.nvim")

  (pkg :name "doom-one-theme"
       :url "NTBBloodbath/doom-one.nvim")

  (pkg :name "catppuccino-theme"
       :url "Pocco81/Catppuccino.nvim")

  (pkg :name "darcula-solid-theme"
       :url "briones-gabriel/darcula-solid.nvim")

  (pkg :name "one-theme"
       :url "rakr/vim-one")

  (pkg :name "edge-theme"
       :url "sainnhe/edge")

  (pkg :name "papercolor-theme"
       :url "NLKNguyen/papercolor-theme")

  (pkg :name "limestone-theme"
       :url "tsbohc/limestone")

  (pkg :name "zenbones-theme"
       :url "mcchrish/zenbones.nvim")

  (pkg :name "zephyr-theme"
       :url "glepnir/zephyr-nvim")

  (pkg :name "modus-theme"
       :url "ishan9299/modus-theme-vim")

  (pkg :name "nvcode-theme"
       :url "ChristianChiarulli/nvcode-color-schemes.vim"))


configure-packages

;;; packages.fnl ends here
