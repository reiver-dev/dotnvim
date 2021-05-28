(module my.packages
  {require {packer packer}})


(def- packer-use packer.use)
(def- packer-load)

(defn- argpairs-1 [tbl n k v ...]
  (when k
    (tset tbl k v))
  (if (< 0 n)
    (argpairs-1 tbl (- n 2) ...)
    tbl))


(defn- argpairs [...]
  (argpairs-1 {} (- (select :# ...) 2) ...))


(defn- pkg [...]
  (let [opts (argpairs ...)]
    (tset opts :as opts.name)
    (tset opts 1 opts.url)
    (set opts.name nil)
    (set opts.url nil)
    (packer-use opts)))


(defn- make-set [...]
  (let [res {}]
    (each [_ arg (ipairs [...])]
      (tset res arg true))
    res))


(defn configure-packages []
  (pkg :name :packer.nvim
       :url "wbthomason/packer.nvim"
       :opt true)

  (pkg :name :fennel
       :url "bakpakin/Fennel"
       :opt true
       :run #(_T :bootstrap.fennel.ensure_compiler :setup {:force true}))

  (pkg :name :conjure
       :url "Olical/conjure"
       :ft ["fennel"]
       :opt true)

  (pkg :name "compe"
       :url "hrsh7th/nvim-compe"
       :opt true
       :event ["InsertEnter"]
       :config #(_T :my.pack.compe :setup))

  (pkg :name :compe-conjure
       :url "tami5/compe-conjure"
       :after ["conjure" "compe"])

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

  (pkg :name "fennel.vim"
       :url "bakpakin/fennel.vim")

  (pkg :name "readline.vim"
       :url "ryvnf/readline.vim"
       :event "CmdlineEnter")

  (pkg :name "vim-fish"
       :url "dag/vim-fish")

  (pkg :name "snippets.nvim"
       :url "norcalli/snippets.nvim"
       :event "InsertCharPre")

  ;; LSP
  (pkg :name :lspconfig
       :url "neovim/nvim-lspconfig"
       :module ["lspconfig"]
       :cmd [:LspInfo :LspStart :LspStop :LspRestart]
       :opt true)

  (pkg :name :lspsaga
       :url "glepnir/lspsaga.nvim"
       :cmd ["Lspsaga"]
       :module "lspsaga"
       :config #(_T :my.pack.lspsaga :setup))

  (pkg :name :lsptrouble
       :url "folke/lsp-trouble.nvim"
       :module "trouble"
       :config #(_T :my.pack.lsptrouble :setup))

  (pkg :name :lspcolors
       :url "folke/lsp-colors.nvim")

  (pkg :name :vista
       :url "liuchengxu/vista.vim"
       :cmd ["Vista"])

  ;; Treesitter
  (pkg :name "nvim-treesitter"
       :url "nvim-treesitter/nvim-treesitter"
       :config #(_T :my.treesitter :setup))

  (pkg :name "nvim-treesitter-playground"
       :url "nvim-treesitter/playground")

  (pkg :name "nvim-treesitter-rainbow"
       :url "p00f/nvim-ts-rainbow")

  ;; File-specific
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
       :url "glepnir/galaxyline.nvim"
       :branch "main"
       :requires [:devicons]
       :config #(require "my.ui.galaxyline"))

  (pkg :name :better-whitespace
       :url "ntpeters/vim-better-whitespace"
       :config #(set vim.g.better_whitespace_filetypes_blacklist
                     (vim.tbl_flatten
                       [["packer"]
                        vim.g.better_whitespace_filetypes_blacklist])))

  (pkg :name "colorbuddy"
       :url "tjdevries/colorbuddy.nvim")

  (pkg :name "lush"
       :url "rktjmp/lush.nvim")

  (pkg :name "jellybeans-theme"
       :url "metalelf0/jellybeans-nvim")

  (pkg :name "onedark-theme"
       :url "olimorris/onedark.nvim")

  (pkg :name "darcula-solid-theme"
       :url "briones-gabriel/darcula-solid.nvim"
       :config #(vim.cmd "colorscheme darcula-solid"))

  (pkg :name "limestone-theme"
       :url "tsbohc/limestone")

  (pkg :name "zephyr-theme"
       :url "glepnir/zephyr-nvim")

  (pkg :name "nvcode-theme"
       :url "ChristianChiarulli/nvcode-color-schemes.vim"))


;;; packages.fnl ends here
