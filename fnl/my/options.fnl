(module my.options)
   

(defn- seto [name value]
  (tset vim.o name value))

(defn- setb [name value]
  (tset vim.o name value)
  (tset vim.bo name value))

(defn- setw [name value]
  (tset vim.o name value)
  (tset vim.wo name value))


(defn setup []
  (setw :number true)
  (setw :relativenumber true)
  (setw :colorcolumn "+1")
  (setb :textwidth 79)

  (seto :clipboard "unnamedplus")
  (seto :mouse "a")
  (seto :termguicolors true)
  (seto :autochdir true)
  (seto :shortmess "Ic")
  (seto :undofile true)
  (seto :showtabline 2)
  (seto :hidden true)
  (seto :completeopt "menuone,noinsert,noselect")

  (vim.cmd "let mapleader=\",\"")
  (vim.cmd "let maplocalleader=\";\""))
