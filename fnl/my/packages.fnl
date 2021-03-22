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


(defn- configure-packages []
  (pkg :name :packer.nvim
       :url "wbthomason/packer.nvim"
       :opt true)

  (pkg :name :fennel
       :url "bakpakin/Fennel"
       :opt true)

  (pkg :name :conjure
       :url "Olical/conjure"
       :opt true
       :ft "fennel"
       :config (fn [...]
                 (_T :compe :register_source
                     "conjure" (require "compe_conjure"))))
  
  (pkg :name :compe-conjure
       :url "tami5/compe-conjure"
       :module "compe_conjure"
       :opt true)
  
  (pkg :name :colorizer
       :url "norcalli/nvim-colorizer.lua"
       :config (fn [] (_T :colorizer :setup)))
  
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
       :run ["cargo" "build" "--release"]
       :disable (= "" (vim.fn.exepath "cargo")))
  
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
       :url "ryvnf/readline.vim")

  (pkg :name "which-key"
       :url "liuchengxu/vim-which-key")

  (pkg :name "vim-fish"
       :url "dag/vim-fish")
  
  (pkg :name "compe"
       :url "hrsh7th/nvim-compe"
       :config (fn [] (_T :my.pack.compe :setup)))

  (pkg :name "snippets.nvim"
       :url "norcalli/snippets.nvim")
  
  ;; LSP
  (pkg :name :lspconfig
       :url "neovim/nvim-lspconfig")

  (pkg :name :lspsaga
       :url "glepnir/lspsaga.nvim"
       :config #(_T :my.pack.lspsaga :setup))
  
  (pkg :name :vista
       :url "liuchengxu/vista.vim")

  ;; Treesitter
  (pkg :name "nvim-treesitter"
       :url "nvim-tregsitter/nvim-treesitter"
       :config #(_T :my.treesitter :setup))

  (pkg :name "nvim-treesitter-playground"
       :url "nvim-treesitter/playground")

  (pkg :name "nvim-treesitter-rainbow"
       :url "p00f/nvim-ts-rainbow")

  ;; File-specific
  (pkg :name "python-pep8-indent"
       :url "Vimjas/vim-python-pep8-indent")
  
  ;; Editing
  (pkg :name :table-mode
       :url "dhruvasagar/vim-table-mode")

  (pkg :name :tabular
       :url "godlygeek/tabular")

  (pkg :name :easy-align
       :url "junegunn/vim-easy-align")

  (pkg :name "matchup"
       :url "andymass/vim-matchup"
       :config (fn []
                 (set vim.g.matchup_matchparen_offscreen {:method :popup})))

  (pkg :name :surround
       :url "tpope/vim-surround")

  (pkg :name :visual-multi
       :url "mg979/vim-visual-multi")
  
  ;; VCS
  (pkg :name :signify
       :url "mhinz/vim-signify")
  
  ;; Repl
  (pkg :name "iron.nvim"
       :url "hkupty/iron.nvim")

  ;; Telescope
  (pkg :name "telescope"
       :url "nvim-lua/telescope.nvim"
       :config #(_T :my.pack.telescope :setup))

  ;; FileTree
  (pkg :name "vinegar"
       :url "tpope/vim-vinegar")

  (pkg :name "tree"
       :url "kyazdani42/nvim-tree.lua"
       :config (_T :my.pack.tree :setup))

  (pkg :name :asyncrun
       :url "skywind3000/asyncrun.vim"
       :config (fn [] (_T :my.pack.asyncrun :setup)))

  (pkg :name :asynctasks
       :url "skywind3000/asynctasks.vim")
 
  ;; UI
  (pkg :name :devicons
       :url "kyazdani42/nvim-web-devicons"
       :config #(_T :nvim-web-devicons :setup))
 
  (pkg :name :galaxyline
       :url "glepnir/galaxyline.nvim"
       :branch "main"
       :requires [:devicons]
       :config #(require "my.ui.galaxyline"))

  (pkg :name "colorbuddy"
       :url "tjdevries/colorbuddy.nvim")

  (pkg :name "modus-theme"
       :url "ishan9299/modus-theme-vim")

  (pkg :name "zephyr-theme"
       :url "glepnir/zephyr-nvim")

  (pkg :name "nvcode-theme"
       :url "ChristianChiarulli/nvcode-color-schemes.vim"
       :config #(vim.cmd "colorscheme nvcode")))


(defn setup []
  (configure-packages))

;;; packages.fnl ends here
