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
  (let [dir (b.get-local bufnr :directory)
        cfg (find-mypy-config dir)
        launch-dir (or (and cfgdir (p.parent cfgdir)) dir)]
    (b.set-local bufnr :python :mypy :config cfg)
    (b.set-local bufnr :python :mypy :directory launch-dir)
    launch-dir))


(defn- relative-path [path root]
  (p.trim (path:gsub root "") p.separator?))


(defn- handle-result [bufnr report-fn cleanup-fn jobid result]
  (cleanup-fn)
  (let [entries (parse-output result.stdout)]
    (report-fn entries))
  (log "Mypy Finished" :jobid jobid :result result))


(def- default-configuration
  ["--implicit-optional"
   "--allow-redefinition"

   "--check-untyped-defs"

   "--disallow-any-generics"
   "--disallow-subclassing-any"
   "--disallow-incomplete-defs"
   "--disallow-untyped-calls"
   "--disallow-untyped-decorators"
   "--disallow-untyped-defs"

   "--disallow-any-unimported"
   "--no-implicit-reexport"

   "--strict-equality"

   "--warn-incomplete-stub"
   "--warn-redundant-casts"
   "--warn-unused-ignores"
   "--warn-return-any"])


(defn- table-concat [...]
  (local result {})
  (var pos 1)
  (for [i 1 (select :# ...)]
    (let [tbl (select i ...)]
      (when tbl
        (for [j 1 (length tbl)]
          (let [val (. tbl j)]
            (when val
              (tset result pos val)
              (set pos (+ pos 1))))))))
  result)


(defn run [bufnr report-fn]
  (let [directory (mypy-directory bufnr)
        _ (log "Mypy directory" :dir directory)
        has-config (not= nil (b.get-local bufnr :python :mypy :config))
        current (relative-path (b.get-local bufnr :file) directory)
        tmpname (j.backup-buffer bufnr)
        cleanup-fn #(vim.loop.fs_unlink tmpname)
        arguments (table-concat
                    (if has-config [] default-configuration)
                    ["--show-column-numbers"
                     "--show-error-codes"
                     "--no-pretty"
                     "--shadow-file" current tmpname
                     current])
        command (python.module-command bufnr :mypy (unpack arguments))
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
