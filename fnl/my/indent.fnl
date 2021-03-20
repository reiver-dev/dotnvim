(module my.indent)


(defn- current-line []
  (vim.fn.getline "."))


(def- indent-blank-line-command "\\<End>x\\<C-o>==\\<End>\\<Left>\\<Del>")
(def- indent-command "\\<C-o>==")
(def- tab-command "\\<Tab>")


(defn- indent []
  (if (string.find (current-line) "^%s*$")
    (vim.cmd indent-blank-line-command)
    (vim.cmd indent-command)))


(defn- keybind []
  (vim.api.nvim_set_keymap
    :i :<Tab> :<C-o>== {:silent true :noremap true}))


(defn- setb [name value]
  (tset vim.o name value)
  (tset vim.bo name value))


(defn- options []
  (setb :tabstop 8)
  (setb :softtabstop 4)
  (setb :shiftwidth 4)
  (setb :expandtab true)
  (setb :autoindent true)
  (setb :smartindent true)
  (setb :lispwords (.. vim.o.lispwords ",module")))


(defn setup []
  (options))
