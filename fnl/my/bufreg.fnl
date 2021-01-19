(module my.bufreg
  {require {u my.util}})


(def- global-buffer-registry (setmetatable {} {:__mode :v}))


(def current-buffer vim.api.nvim_get_current_buf)
(def buffer-valid? vim.api.nvim_buf_is_valid)


(defn- new-buffer-state [bufnr]
  "Create new state value for BUFNR buffer."
  (let [bufferstate {:bufnr bufnr}]
    (tset global-buffer-registry bufnr bufferstate)
    (vim.fn.setbufvar bufnr "__buffer_state_ref_holder__" (fn [] bufferstate))
    bufferstate))


(defn- get-buffer-state [bufnr]
  "Get state for BUFNR buffer. Create new state if missing."
  (or (. global-buffer-registry bufnr) (new-buffer-state bufnr)))
  

(defn- buffer [bufnr]
  (vim.validate {:bufnr [bufnr :number]})
  (if (< 0 bufnr)
    bufnr
    (current-buffer)))


(defn set-local [bufnr ...]
  "Associate value with BUFNR buffer state."
  (u.nset global-buffer-registry (buffer bufnr) ...))


(defn get-local [bufnr ...]
  "Get associated value from BUFNR buffer state."
  (u.nget global-buffer-registry (buffer bufnr) ...))


(defn- on-unload [_event bufnr]
  (set-local bufnr :loaded false)
  (tset global-buffer-registry bufnr nil)
  nil)


(defn new []
  "Ensure buffer state exists for current buffer."
  (let [bufnr (tonumber (vim.fn.expand "<abuf>"))
        bufferstate (get-buffer-state bufnr)]
    (when (and (= bufferstate.loaded nil)
               (vim.api.nvim_buf_is_loaded bufnr))
      (vim.api.nvim_buf_attach bufnr false {:on_detach on-unload})
      (set bufferstate.loaded true)) 
    nil))


(def- autocmd
  "augroup buffer_registry
autocmd VimEnter,BufNew,BufNewFile,BufReadPre * call v:lua._T('my.bufreg', 'new')
augroup END")


(defn state []
  "Get global buffer registry state."
  global-buffer-registry)


(defn setup []
  (vim.api.nvim_exec autocmd false))
