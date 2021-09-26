(module my.scratch)


(def- window-mods [:vertical
                   :aboveleft :leftabove
                   :rightbelow :belowright
                   :topleft
                   :botright])


(def- window-mods-short
  {:vert :vertical
   :lefta :leftabove
   :abo :aboveleft
   :rightb :rightbelow
   :bel :belowright
   :to :topleft
   :bo :botright})


(defn make-scratch-buffer [name]
  (local bufnr (vim.api.nvim_create_buf true true))
  (vim.api.nvim_buf_set_name bufnr name)
  bufnr)


(defn make-or-switch [name]
  (local name (if (and (not= nil name) (not= "" name))
                name
                "[Scratch]"))
  (var bufnr (vim.fn.bufnr name))
  (when (= bufnr -1)
    (set bufnr (make-scratch-buffer name)))
  (assert (< 0 bufnr))
  (vim.cmd (.. "sbuffer " bufnr)))


(defn setup []
  (vim.cmd "command! -nargs=? Scratch lua _T('my.scratch', 'make-or-switch', <q-args>)"))
