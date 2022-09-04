(fn current-line []
  (vim.fn.getline "."))


(local indent-blank-line-command "\\<End>x\\<C-o>==\\<End>\\<Left>\\<Del>")
(local indent-command "\\<C-o>==")
(local tab-command "\\<Tab>")


(fn indent []
  (if (string.find (current-line) "^%s*$")
    (vim.cmd indent-blank-line-command)
    (vim.cmd indent-command)))


(fn keybind []
  (vim.api.nvim_set_keymap
    :i :<Tab> :<C-o>== {:silent true :noremap true}))


(fn setb [name value]
  (tset vim.o name value)
  (tset vim.bo name value))


(fn options []
  (setb :tabstop 8)
  (setb :softtabstop 4)
  (setb :shiftwidth 4)
  (setb :expandtab true)
  (setb :lispwords (.. vim.o.lispwords ",module,collect,icollect")))


(fn setup []
  (options))


{: setup}
