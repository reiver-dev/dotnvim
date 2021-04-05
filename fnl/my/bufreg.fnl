(module my.bufreg
  {require {u my.util}})


(defonce- global-buffer-state (setmetatable {} {:__mode :v}))
(defonce- global-buffer-ids {})
(defonce- global-free-ids {})
(defonce- generate-new-id (u.counter))


(def- define-autocmd
  "augroup my_buffer_registry
autocmd!
autocmd VimEnter * lua _T('my.bufreg', 'autocmd-new')
autocmd BufNew,BufNewFile * lua _T('my.bufreg', 'autocmd-new')
autocmd BufReadPre * lua _T('my.bufreg', 'autocmd-new')
augroup END")


(def- define-function
  "function! BufferStateId(expr) abort
  let l:State = getbufvar(a:expr, '__buffer_state_ref_holder__', v:null)
  if l:State != v:null
    return l:State()
  else
    return v:null
  endif
  endfunction")


(defn- return-id [bufnr id]
  "Detach ID from BUFNR. Ensure ID is available for new buffers."
  (let [current-id (. global-buffer-ids bufnr)]
    (when (= id current-id)
      (tset global-buffer-ids bufnr nil)))
  (tset global-free-ids id true))


(defn- claim-id [bufnr]
  "Return new currently unique id for BUFNR."
  (var id (next global-free-ids))
  (if id
    (tset global-free-ids id nil)
    (set id (generate-new-id)))
  (tset global-buffer-ids bufnr id)
  id)


(defn- make-anchor [state]
  "Make sure buffer id is reclamed when STATE is destroyed."
  (let [ud (newproxy true)
        mt (getmetatable ud)
        id state.id
        bufnr state.bufnr]
    (tset mt :__gc (fn [] (return-id bufnr id)))
    (setmetatable state {:__anchor ud})
    state))


(def- current-buffer vim.api.nvim_get_current_buf)


(defn- new-buffer-state [bufnr]
  "Create new state for BUFNR.
  Ensure the state is destroyed when buffer unloaded."
  (let [id (claim-id bufnr)
        bufferstate (make-anchor {:bufnr bufnr :id id})]
    (tset global-buffer-state id bufferstate)
    (vim.fn.setbufvar bufnr "__buffer_state_ref_holder__" (fn [] bufferstate.id))
    bufferstate))


(defn- buffer-id [bufnr]
  "Get id for BUFNR. If BUFNR is non-positive, consider it current buffer."
  (let [t (type bufnr)]
     (assert (= t :number) (.. "BUFNR must be number, got: " t)))
  (let [state-id (. global-buffer-ids (if (< 0 bufnr)
                                        bufnr
                                        (current-buffer)))]
    state-id))


(defn ensure-state [bufnr]
  "Ensure buffer state exists for BUFNR buffer."
  (var id (vim.fn.BufferStateId bufnr))
  (when (= id vim.NIL)
    (set id (. (new-buffer-state bufnr) :id)))
  (assert (~= (. global-buffer-state id) nil) "No state for id")
  (assert (= (. global-buffer-ids bufnr) id) "No buffer to id mapping")
  id)


(defn autocmd-new []
  "Ensure buffer state exists for current buffer."
  (ensure-state (tonumber (vim.fn.expand "<abuf>"))))


(defn set-local [bufnr ...]
  "Associate value with BUFNR buffer state."
  (let [id (or (buffer-id bufnr) (ensure-state bufnr))
        initial ...]
    (when id
      (u.nset global-buffer-state id ...)
      (when (= initial nil)
        (vim.api.nvim_buf_del_var bufnr "__buffer_state_ref_holder__")))))


(defn get-local [bufnr ...]
  "Get associated value from BUFNR buffer state."
  (let [id (buffer-id bufnr)]
    (when id
      (u.nget global-buffer-state id ...))))


(defn update-local [bufnr ...]
  (let [id (or (buffer-id bufnr) (ensure-state bufnr))
        initial ...]
    (assert (not= nil initial) "First key must not be nil")
    (when id
      (u.nupd global-buffer-state id ...))))


(defn state []
  "Get global buffer registry state."
  global-buffer-state)


(defn allocated-state-ids []
  "Return currently allocated state ids for buffers."
  global-buffer-ids)


(defn free-state-ids []
  "Return currently freed state ids for buffers."
  global-free-ids)


(defn setup []
  (vim.api.nvim_exec define-autocmd false)
  (vim.api.nvim_exec define-function false))
