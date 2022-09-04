(fn seto [name value]
  (tset vim.o name value))

(fn setb [name value]
  (tset vim.o name value)
  (tset vim.bo name value))

(fn setw [name value]
  (tset vim.o name value)
  (tset vim.wo name value))

(fn list [...]
  (table.concat [...] ","))


(fn setup []
  (seto :timeoutlen 300) ; 1000
  (seto :lazyredraw true)

  (setw :number true)
  (setw :relativenumber false)
  (setw :signcolumn "yes")

  (seto :showmode false)
  (seto :showtabline 2)
  (seto :shortmess "filnxtToOFIc")
  (seto :scrolloff 2)
  (seto :cmdheight 2)
  (seto :termguicolors true)
  (setw :colorcolumn "79")

  (seto :completeopt "menu,menuone,noselect")

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


{: setup}
