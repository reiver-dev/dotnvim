(module my.checkers.mypy
  {require {b my.bufreg
            j my.check.job
            w my.fswalk
            p my.pathsep
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


(defn- find-mypy-config [directory]
  (let [files (w.gather directory ["mypy.ini" "setup.cfg"])]
    (when files
      (or (-?> files (. :mypy.ini) (. 1))
          (-?> files (. :setup.cfg) (. 1))))))


(defn- mypy-directory [bufnr]
  (b.update-local bufnr :python :mypy :config-dir
                  (fn [cfgdir]
                   (if cfgdir
                     cfgdir
                     (let [dir (b.get-local bufnr :directory)
                           cfgdir (find-mypy-config dir)]
                       (or (and cfgdir (p.parent cfgdir))
                           dir))))))


(defn- relative-path [path root]
  (p.trim (path:gsub root "") p.separator?))


(defn- handle-result [bufnr report-fn cleanup-fn jobid result]
  (cleanup-fn)
  (let [entries (parse-output result.stdout)]
    (report-fn entries))
  (log "Mypy Finished" :jobid jobid :result result))


(defn run [bufnr report-fn]
  (let [directory (mypy-directory bufnr)
        _ (log "Mypy directory" :dir directory)
        current (relative-path (b.get-local bufnr :file) directory)
        tmpname (j.backup-buffer bufnr)
        cleanup-fn #(vim.loop.fs_unlink tmpname)
        command (python.module-command bufnr :mypy
                                       "--show-column-numbers"
                                       "--show-error-codes"
                                       "--no-pretty"
                                       "--shadow-file" current tmpname
                                       current)
        (ok res) (pcall
                   (fn []
                     (j.execute-command
                       bufnr command directory
                       (partial handle-result bufnr report-fn cleanup-fn))))]
    (when (not ok)
      (cleanup-fn)
      (error res))
    (log "Mypy Started" :bufnr bufnr :jobid res)
    res))


(defn cancel [bufnr jobid]
  (j.cancel jobid))
