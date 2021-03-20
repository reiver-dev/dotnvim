(module my.terminal)


(defn getpid [bufnr]
  (vim.api.nvim_buf_get_var bufnr :terminal_job_pid))


(defn terminal? [bufnr]
  (= (vim.api.nvim_buf_get_option bufnr :buftype) "terminal"))


(defn running? [bufnr]
  (let [chan (vim.api.nvim_buf_get_option bufnr :channel)]
    (when chan (= -1 (. (vim.fn.jobwait [chan]) 0)))))
  

(defn- find [func iter state idx]
  (let [(idx value) (iter state idx)]
    (when (~= nil idx)
      (if (func value)
        value
        (find func iter state idx)))))


(defn find-terminal [pid]
  (find (fn [bufnr] (and (terminal? bufnr)
                         (= pid (getpid bufnr))))
        (ipairs (vim.api.nvim_list_bufs))))


(defn- find-keymap [bufnr mode key]
  (or (find (fn [map] (= (. map :lhs) key))
           (ipairs (vim.api.nvim_buf_get_keymap bufnr mode)))
      (find (fn [map] (= (. map :lhs) key))
           (ipairs (vim.api.nvim_get_keymap mode)))))


(defn- execute-prefix-1 []
  (let [input (vim.fn.nr2char (vim.fn.getchar))
        sequence (.. "<C-X>" input)
        keys (vim.api.nvim_replace_termcodes sequence true true true)]
    (vim.api.nvim_feedkeys keys :m true)))
  

(defn- schedule-insert-mode []
  (let [bufnr (vim.api.nvim_get_current_buf)]
    (vim.schedule
      (fn []
        (let [current (vim.api.nvim_get_current_buf)]
          (when (= current bufnr)
            (vim.cmd :startinsert)))))))


(defn execute-prefix [prefix]
  (_T :my.simple :message "Key <C-x> ?" (vim.fn.getcmdline))
  (when (or (not (pcall execute-prefix-1)) (~= "" vim.v.errmsg))
    (schedule-insert-mode)))
  

(defn- setup-bindings []
  (let [bind-1 vim.api.nvim_set_keymap
        bind (fn [key cmd] (bind-1 :t key cmd {:noremap true}))]
    (bind :<C-x> "<C-\\><C-N>:lua _T('my.terminal', 'execute-prefix')<CR>")
    (bind :<C-y> "<C-\\><C-N>pi")))
        

(defn chdir [bufnr directory]
  (vim.api.nvim_buf_set_var bufnr :default_directory directory)
  (vim.api.nvim_buf_call
    bufnr (fn [] (vim.cmd (.. "lcd " (vim.fn.fnameescape directory))))))


(def- autocmd
  "augroup boostrap_terminal
  autocmd!
  autocmd TermOpen * setlocal nonumber norelativenumber
  augroup end
  ")


(defn setup []
  (setup-bindings)
  (vim.api.nvim_exec autocmd false))
  
