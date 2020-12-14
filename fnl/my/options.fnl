(module my.options
  {require {s my.simple}})
   

(defn- seto [name value]
  (tset vim.o name value))

(defn- setb [name value]
  (tset vim.o name value)
  (tset vim.bo name value))

(defn- setw [name value]
  (tset vim.o name value)
  (tset vim.wo name value))


(defn- list [...]
  (table.concat [...] ","))


(defn setup []
  (seto :timeoutlen 300) ; 1000
  (seto :lazyredraw true)

  (setw :number true)
  (setw :relativenumber false)

  (seto :showmode false)
  (seto :signcolumn "yes")
  (seto :showtabline 2)
  (seto :shortmess "filnxtToOFIc")
  (seto :scrolloff 2)
  (seto :cmdheight 2)
  (seto :termguicolors true)
  (setw :colorcolumn "79")

  (seto :completeopt "menuone,noinsert,noselect")

  (seto :mouse "a")
  (seto :undofile true)

  (seto :smartcase true)
  (seto :wrap false)
  (seto :joinspaces false)

  (seto :hidden true)
  (seto :splitright true)
  (seto :splitbelow true)

  (setw :listchars
        (list
          "nbsp:¬"
          "eol:¶"
          "extends:»"
          "precedes:«"
          "trail:•"))

  (seto :diffopt
        (list
          "internal"
          "filler"
          "closeoff"
          "iwhite"
          "algorithm:patience"
          "indent-heuristic"))

  (vim.cmd "let mapleader=\",\"")
  (vim.cmd "let maplocalleader=\";\""))
