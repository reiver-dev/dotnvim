(module my.terminal
  {require {fun my.fun}})


(defn- job-running? [job]
  (local (ok res) (vim.api.nvim_call_function [[job] 0]))
  (if ok (= (. res 1) -1) false))


(defn- job-pid [job]
  (local (ok pid) (pcall vim.api.nvim_call_function :jobpid [job]))
  (if ok pid -1))


(defn find-terminal [pid]
  (when (< 0 pid)
    (let [chan (fun.find (fn [chan]
                           (and (= chan.mode :terminal)
                                (= chan.stream :job)
                                (vim.api.nvim_buf_is_valid chan.buffer)
                                (= (job-pid chan.id) pid)))
                         (vim.api.nvim_list_chans))]
      chan)))


(defn- find-keymap [bufnr mode key]
  (or (fun.find (fn [map] (= (. map :lhs) key))
                (ipairs (vim.api.nvim_buf_get_keymap bufnr mode)))
      (fun.find (fn [map] (= (. map :lhs) key))
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
    (bind :<C-g> "<C-\\><C-N>")
    (bind :<C-x> "<C-\\><C-N>:lua _T('my.terminal', 'execute-prefix')<CR>")
    (bind :<C-y> "<C-\\><C-N>pi")))


(defn chdir [bufnr directory]
  (vim.api.nvim_buf_set_var bufnr :default_directory directory)
  (vim.api.nvim_buf_call
    bufnr (fn [] (vim.cmd (.. "lcd " (vim.fn.fnameescape directory))))))


(defn gather-data [kind]
  (local point (require "my.point"))
  (match kind
    :lines (vim.api.nvim_buf_get_lines (point.line-begin) (point.line-end))
    :region []
    :buffer []
    _ []))


(defn- lines-trim-region [lines col-begin col-end]
  (local len (length lines))
  (if
    (< 1 len)
    (do
      (tset lines 1 (string.sub (. lines 1) (math.max 1 col-begin)))
      (tset lines len (string.sub (. lines len) 1 col-end)))
    (< 0 len)
    (tset lines 1 (string.sub (. lines 1) (math.max 1 col-begin) col-end)))
  lines)


(defn- lines-trim-block [lines col-begin col-end]
  (for [i 1 (length lines)]
    (tset lines i (string.sub (. lines i) (math.max 1 col-begin))))
  lines)


(defn- lines-max-length [lines]
  (var maxlen 0)
  (for [i 1 (length lines)]
    (set maxlen (math.max maxlen (length (. lines i)))))
  maxlen)


(defn string-indent [line]
  (or (string.find line "[^%s]") 0))


(defn- lines-dedent [lines]
  (var min-indent 2147483647)
  (for [i 1 (length lines)]
    (local line (. lines 1))
    (local indent (string-indent line))
    (when (not= 0 indent)
      (set min-indent (math.min min-indent indent))))
  (when (< 1 min-indent)
    (for [i 1 (length lines)]
      (tset lines i (string.sub (. lines i) min-indent))))
  lines)


(defn- lines-dedent-nonempty [lines]
  (local nlines [])
  (var min-indent 0)
  (for [i 1 (length lines)]
    (local line (. lines 1))
    (local indent (string-indent line))
    (when (not= nil indent)
      (set min-indent (math.min min-indent indent))
      (tset nlines (+ 1 (length nlines)) line)))
  (when (< 1 min-indent)
    (for [i 1 (length nlines)]
      (tset lines i (string.sub (. lines i) min-indent))))
  nlines)


(defn- lines-reindent [lines]
  (local base-indent (string-indent (. lines 1)))
  (when (< 1 base-indent)
    (tset lines 1 (string.sub (. lines 1) base-indent))
    (for [i 2 (length lines)]
      (local line (. lines i))
      (local indent (string-indent line))
      (if (or (<= base-indent indent) (= indent 0))
        (tset lines i (string.sub line base-indent))
        (tset lines i (.. (string.rep " " (+ 1 (- base-indent indent)))
                          line)))))
  lines)


(defn- lines-extend-column [lines col]
  (local len (length lines))
  (if (= len 0) col
    (< (length (. lines 1)) col) 2147483647
    col))


(def- visual-register :v)


(defn- get-normal-visual-lines [?register]
  (local reg (string.sub (or ?register visual-register) 1 1))
  (vim.cmd (string.format "silent normal gv\"%.1sy" reg))
  (values (vim.fn.getreg reg 1 1) (vim.fn.getregtype reg)))


(defn selection [range line1 line2]
  (local point (require "my.point"))
  (match (string.byte (. (vim.api.nvim_get_mode) :mode) 1)
    110 (let [(bl bc) (point.range-begin)
              (el ec) (point.range-end)]
          (if (and (= range 2) (= bl line1) (= el line2))
            (let [(lines regtype) (get-normal-visual-lines)]
              (if (= 86 (string.byte regtype 1))
                (lines-dedent lines)
                lines))
            (vim.api.nvim_buf_get_lines 0 (- line1 1) line2 false)))

    118 (let [(bl bc el ec) (point.visual-point)
              curswant (. (vim.fn.winsaveview) :curswant)
              lines (vim.api.nvim_buf_get_lines 0 (- line1 1) line2 false)]
          (match (string.byte (vim.fn.visualmode) 1)
            ;; v region
            118 (lines-trim-region lines (+ bc 1) (+ ec 1))
            ;; V line
            86 (lines-dedent lines)
            ;; ^V block
            22 (lines-trim-block lines (+ bc 1) (math.max (+ ec 1) curswant))
            ;; What?
            _ lines))))


(defn send-region [range line1 line2 dst-expr ...]
  (local bufnr (or (tonumber dst-expr) (vim.fn.bufnr dst-expr)))
  (local chan-id (vim.api.nvim_buf_get_var bufnr "terminal_job_id"))
  (local lines (selection range line1 line2))
  (local text (let [numlines (length lines)]
                (if
                  (= 0 numlines) "\n"
                  (= 1 numlines) (.. (. lines 1) "\n")
                  (do
                    (tset lines (+ 1 numlines) "\n")
                    (table.concat lines "\n")))))
  (vim.api.nvim_chan_send chan-id text))



(defn send-visual []
  (local p (require "my.point"))
  (print (table.concat (selection 0 0 0) "\n")))


(def- autocmd
  "augroup boostrap_terminal
  autocmd!
  autocmd TermOpen * setlocal nonumber norelativenumber
  augroup end
  ")



(def- commands
  (.. "command! -range -nargs=1 -complete=buffer TermSendRegion "
      "call v:lua._T('my.terminal', 'send-region', <range>, <line1>, <line2>, <q-args>)"))


(defn setup []
  (setup-bindings)
  (vim.api.nvim_exec autocmd false)
  (vim.api.nvim_set_keymap :v "<leader>x"
                           "<Cmd>lua _T('my.terminal', 'send-visual')<CR>"
                           {:noremap true})
  (vim.cmd commands))

