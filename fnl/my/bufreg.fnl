(module my.bufreg)


(def- state (setmetatable {} {:__mode :v}))


(defn- assign-1 [root n map key ...]
  (if (< 2 n)
    (do
      (var nested (. map key))
      (when (not nested)
        (let [new {}]
          (tset map key new)
          (set nested new)))
      (assign-1 root (- n 1) nested ...))
    (do
      (tset map key ...)
      root)))
  

(defn- assoc [map ...]
  (assign-1 map (select :# ...) map ...))


(defn- nget-1 [map n key ...]
  (let [nested (. map key)]
    (if (and (< 1 n) nested)
      (nget-1 nested (- n 1) ...)
      nested)))
    

(defn- nget [map ...]
  (nget-1 map (select :# ...) ...))


(def current-buffer vim.api.nvim_get_current_buf)
(def buffer-valid? vim.api.nvim_buf_is_valid)
  

(defn- buffer [bufnr]
  (vim.validate {:bufnr [bufnr :number]})
  (if (< 0 bufnr)
    bufnr
    (current-buffer)))


(defn set-local [bufnr ...]
  (assoc state (buffer bufnr) ...))


(defn get-local [bufnr ...]
  (nget state (buffer bufnr) ...))


(defn- on-unload [_event bufnr]
  (set-local bufnr :loaded false)
  (tset state bufnr nil)
  nil)


(defn new []
  (let [bufnr (tonumber (vim.fn.expand "<abuf>"))]
    (var bufferstate (. state bufnr))
    (when (not bufferstate)
      (set bufferstate {:bufnr bufnr})
      (tset state bufnr bufferstate)
      (vim.fn.setbufvar bufnr "__buffer_state_ref_holder__"
                        (fn [] bufferstate)))
    (when (and (= bufferstate.loaded nil)
               (vim.api.nvim_buf_is_loaded bufnr))
      (vim.api.nvim_buf_attach bufnr false {:on_detach on-unload})
      (set bufferstate.loaded true)) 
    nil))


(def- autocmd
  "augroup buffer_registry
autocmd VimEnter,BufNew,BufNewFile,BufReadPre * call v:lua._T('my.bufreg', 'new')
augroup END")


(defn get-state []
  state)


(defn setup []
  (vim.api.nvim_exec autocmd false))
