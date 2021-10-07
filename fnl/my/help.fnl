(module my.help
  {require {fun my.fun
            point my.point
            selection my.selection}})


(defn- lines-to-str [obj]
  (table.concat obj "\n"))


(defn- term-lines-to-str [obj]
  (table.concat obj "\r\n"))


(defn- lines-not-empty [tbl]
  (and
    (not= nil tbl)
    (< 0 (length tbl))
    (not= nil (fun.find #(< 0 (length $1)) tbl))))


(defn- handle-finished-job [state jobid]
  (if (= state.exit 0)
    (do
      (when (lines-not-empty state.stdout)
        (local bufnr (vim.api.nvim_create_buf true true))
        (local chan (vim.api.nvim_open_term bufnr {}))
        (vim.api.nvim_chan_send chan (term-lines-to-str state.stdout))
        (vim.cmd (string.format "tab sbuffer %d" bufnr)))
      (when (lines-not-empty state.stderr)
        (local text (lines-to-str state.stderr))
        (local msg (string.format "Help command stderr:\n%s" text))
        (vim.notify msg vim.log.levels.WARN)))
    (do
      (local msg (string.format "Help command failed:\n%s" (lines-to-str state.stderr)))
      (vim.notify msg vim.log.levels.ERROR))))


(defn- handle-job-data [state jobid data event]
  (match event
    :stdout (set state.stdout data)
    :stderr (set state.stderr data)
    _ (do
        (set state.exit data)
        (handle-finished-job state jobid))))


(defn- process-environment [tbl]
  (when tbl
    (let [base (vim.fn.environ)]
      (each [k v (pairs tbl)]
        (tset base k v))
      base)))


(defn- execute [program]
  (local result {})
  (local handler (partial handle-job-data result))
  (vim.fn.jobstart program
                   {:stdout_buffered true
                    :stderr_buffered true
                    :env (process-environment
                           {:PAGER :cat
                            :MANPAGER :cat
                            :MAN_KEEP_FORMATTING :1})
                    :on_exit handler
                    :on_stdout handler
                    :on_stderr handler}))


(defn show-command [command word count]
  (local text (string.format
                ":%d%s %s" (or count 0)
                command (vim.fn.fnameescape word)))
  (vim.cmd text)
  (values))


(defn show-program [command word count]
  (execute (.. command " " (vim.fn.fnameescape word))))


(defn show-keywordprg [kprg word count]
  (if (= ":" (string.sub kprg 1 1))
    (show-command (string.sub kprg 2) word count)
    (show-program kprg word count)))


(defn try-hover [fallback]
  (if fallback
    (vim.lsp.buf_request
      0
      "textDocument/hover"
      (vim.lsp.util.make_position_params)
      (let [hover vim.lsp.handlers.hover]
        (fn [err result ctx config]
          (when (not (and result
                          result.contents
                          (hover err result ctx config)))
            (fallback)))))
    (vim.lsp.buf.hover)))


(defn- get-keywordprg [bufnr]
  (local (ok val) (pcall vim.api.nvim_buf_get_option bufnr :keywordprg))
  (if ok val (vim.api.nvim_get_option :keywordprg)))


(defn show [count word]
  (let [clients (vim.lsp.buf_get_clients 0)
        kprg (get-keywordprg 0)]
    (if (< 0 (length clients))
      (try-hover (fn [] (show-keywordprg kprg word count)))
      (show-keywordprg kprg word count))))


(defn show-command [count word]
  (local word (or word (vim.fn.expand "<cword>")))
  (local kprg (get-keywordprg 0))
  (show-keywordprg kprg word count))


(defn show-current-word []
  (show vim.v.count (vim.fn.expand "<cword>")))


(defn show-current-selection []
  (let [lines (selection.selection)]
    (when (and lines (< 0 (length lines)))
      (show vim.v.count (. lines 1)))))


(def- command
  "command! -count=0 -nargs=? KeyHelp lua _T('my.help', 'show-command', <count>, <q-args>)")


(def- key-normal
  "<Cmd>lua _T('my.help', 'show-current-word')<CR>")


(def- key-visual
  "<Cmd>lua _T('my.help', 'show-current-selection')<CR>")


(defn setup []
  (vim.cmd command)
  (vim.api.nvim_set_keymap :n :K key-normal {:noremap true})
  (vim.api.nvim_set_keymap :v :K key-visual {:noremap true}))
