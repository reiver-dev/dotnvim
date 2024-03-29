(local window-mods [:vertical
                    :aboveleft :leftabove
                    :rightbelow :belowright
                    :topleft
                    :botright])


(local window-mods-short
  {:vert :vertical
   :lefta :leftabove
   :abo :aboveleft
   :rightb :rightbelow
   :bel :belowright
   :to :topleft
   :bo :botright})


(fn make-scratch-buffer [name]
  (local bufnr (vim.api.nvim_create_buf true true))
  (vim.api.nvim_buf_set_name bufnr name)
  bufnr)


(fn find-buf-by-name [name]
  (var bufnr -1)
  (each [_ num (ipairs (vim.api.nvim_list_bufs)) :until (<= 0 bufnr)]
    (let [bufname (vim.api.nvim_buf_get_name num)]
      (when (= name (string.sub bufname (- (length name))))
        (set bufnr num))))
  bufnr)


(fn make-or-switch [name]
  (local name (if (and (not= nil name) (not= "" name))
                name
                "[Scratch]"))
  (var bufnr (find-buf-by-name name))
  (when (= bufnr -1)
    (set bufnr (make-scratch-buffer name)))
  (assert (< 0 bufnr))
  (vim.cmd (.. "sbuffer " bufnr)))


(fn setup []
  (vim.cmd "command! -nargs=? Scratch lua _T('my.scratch', 'make-or-switch', <q-args>)"))


{: make-scratch-buffer 
 : find-buf-by-name 
 : make-or-switch 
 : setup} 
