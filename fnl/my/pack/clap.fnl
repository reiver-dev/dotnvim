(module my.pack.clap
  {require {hook bootstrap.hook
            pkg bootstrap.pkgmanager}})


(defn- make-table [...]
  (let [tbl {}]
    (each [_ key (ipairs [...])]
      (tset tbl key true))
    tbl))



(defn- kmap [mode key command ...]
  (vim.api.nvim_buf_set_keymap 0 mode key command (make-table ...)))


(defn- keybind []
  (kmap :i :<C-p> "<C-R>=clap#navigation#linewise('up')<CR>" :noremap :silent)
  (kmap :i :<C-n> "<C-R>=clap#navigation#linewise('down')<CR>"
        :noremap :silent))


(defn- refresh-lightline []
  ((. vim.fn "lightline#update")))


(defn setup []
  (tset vim.g :clap_layout {:relative :editor})
  (tset vim.g :clap_theme "dogrun")
  (hook.on.user :ClapOnEnter keybind)
  (hook.on.user :ClapOnExit refresh-lightline))

