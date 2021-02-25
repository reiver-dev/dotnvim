(module my.checkers.mypy
  {require {b my.bufreg
            j my.check.job
            python my.lang.python}})


(def- Error vim.lsp.protocol.DiagnosticSeverity.Error)
(def- Warning vim.lsp.protocol.DiagnosticSeverity.Warning)
(def- Information vim.lsp.protocol.DiagnosticSeverity.Information)
(def- Hint vim.lsp.protocol.DiagnosticSeverity.Hint)


(def- line-pattern
  "([^:]+):(%d+):(%d+): ([^:]+): (.*)")


(defn- parse-line [line]
  (let [(name line col severity msg) (string.match line line-pattern)]
    (when name
      (let [line (- (tonumber line) 1)
            col (- (tonumber col) 1)]
        {:source "mypy"
         :range {:start {:line line :character col}
                 :end {:line line :character (+ col 1)}}
         :severity (match severity
                     :error Error
                     :note Information
                     :warning Warning
                     _ Hint)
         :message msg}))))


(defn- parse-output [lines]
  (let [entries []]
    (each [_ line (ipairs lines)]
      (let [entry (parse-line line)]
        (when entry
          (table.insert entries entry))))
    entries))


(defn run [bufnr report-fn]
  (let [current (vim.fn.fnamemodify (b.get-local bufnr :file) ":t")
        tmpname (j.backup-buffer bufnr)
        command (python.module-command bufnr :mypy
                                       "--show-column-numbers"
                                       "--show-error-codes"
                                       "--shadow-file" current tmpname
                                       current)
        (ok res) (pcall
                   (fn []
                     (j.execute-command
                       bufnr command nil
                       (fn [jobid result]
                         (log "MypyDone" :tmpdata (j.slurp tmpname))
                         (vim.loop.fs_unlink tmpname)
                         (let [entries (parse-output result.stdout)]
                           (report-fn entries))
                         (log "Mypy Finished" :jobid jobid :result result)))))]
    (when (not ok)
      (vim.loop.fs_unlink tmpname)
      (error res))
    (log "Mypy Started" :bufnr bufnr :jobid res)
    res))


(defn cancel [bufnr jobid]
  (j.cancel jobid))
